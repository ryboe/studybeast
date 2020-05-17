// webclient module

resource "google_compute_backend_bucket" "lb_backend" {
  name        = "web-client-lb-backend"
  description = "This backend points to the bucket that holds the static web app we want to serve"
  bucket_name = google_storage_bucket.web_client.name
  enable_cdn  = true
}

# google_compute_global_address is for load balancers.
# google_compute_address is for instances.
resource "google_compute_global_address" "ipv4" {
  name         = "web-client-lb-ipv4"
  description  = "The static IPv4 address assigned to the HTTP(S) load balancer"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_address" "ipv6" {
  name         = "web-client-lb-ipv6"
  description  = "The static IPv6 address assigned to the HTTP(S) load balancer"
  ip_version   = "IPV6"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "https_ipv4" {
  name       = "web-client-lb-forwarding-rule-ipv4"
  target     = google_compute_target_https_proxy.https_target.self_link
  ip_address = google_compute_global_address.ipv4.address
  port_range = 443
}

resource "google_compute_global_forwarding_rule" "https_ipv6" {
  name       = "web-client-lb-forwarding-rule-ipv6"
  target     = google_compute_target_https_proxy.https_target.self_link
  ip_address = google_compute_global_address.ipv6.address
  port_range = 443
}

resource "google_compute_global_forwarding_rule" "http" {
  name       = "web-client-lb-forwarding-rule-http"
  target     = google_compute_target_http_proxy.http_target.self_link
  ip_address = google_compute_global_address.ipv4.address
  port_range = 80
}

# TODO: enable this when you're confident the rest of the architecture is good.
# there's a limit to how many certs you can create/destroy
resource "google_compute_managed_ssl_certificate" "client" {
  provider = google-beta
  name     = "web-client-lb-cert"

  managed {
    domains = ["${var.domain}"]
  }
}

resource "google_compute_target_http_proxy" "http_target" {
  name    = "web-client-lb-target-http"
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_url_map" "http_redirect" {
  name        = "http-redirect-url-map"
  description = "This just redirects all HTTP requests to HTTPS"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "PERMANENT_REDIRECT"
    strip_query            = false
  }

  # This header prevents future requests from going to http:// instead of https://
  header_action {
    # TODO: does this work?
    response_headers_to_add {
      header_name  = "Strict-Transport-Security"
      header_value = "max-age=63072000; includeSubDomains; preload"
      replace      = true
    }
  }
}

resource "google_compute_target_https_proxy" "https_target" {
  name             = "web-client-lb-target-https"
  ssl_certificates = [google_compute_managed_ssl_certificate.client.self_link]
  url_map          = google_compute_url_map.urls.self_link
}

resource "google_compute_url_map" "urls" {
  name            = "web-client-lb-url-map"
  description     = "This just maps all requests to the backend bucket" # TODO: better desc
  default_service = google_compute_backend_bucket.lb_backend.self_link

  # This header prevents future requests from going to http:// instead of https://
  header_action {
    # TODO: does this work?
    response_headers_to_add {
      header_name  = "Strict-Transport-Security"
      header_value = "max-age=63072000; includeSubDomains; preload"
      replace      = true
    }

    # TODO: does this work?
    response_headers_to_add {
      header_name  = "X-Content-Type-Options"
      header_value = "nosniff"
      replace      = true
    }
  }
}

resource "google_dns_record_set" "domain_root_ipv4" {
  name         = "${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "A"
  ttl          = 600
  rrdatas      = [google_compute_global_address.ipv4.address]
}

resource "google_dns_record_set" "domain_root_ipv6" {
  name         = "${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "AAAA"
  ttl          = 600
  rrdatas      = [google_compute_global_address.ipv6.address]
}

resource "google_storage_bucket" "web_client" {
  name = var.bucket_name

  bucket_policy_only = true # use Uniform bucket-level access (protected by IAM). Do not use ACLs. ACLs were a pre-IAM method of access control.

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # Automatically delete files after 30 days.
  lifecycle_rule {
    condition {
      age = "30" # days
    }
    action {
      type = "Delete"
    }
  }
}

data "google_iam_policy" "all_users_storage_getter" {
  binding {
    # objectViewer is necessary for the bucket website configuration to work.
    # The website configuration specifies index.html as the main page and
    # 404.html as the not found page. If we used the more restrictive
    # 'legacyObjectReader' permissions here (which don't permit users to list
    # the bucket), the website configuration won't work.
    role    = "roles/storage.objectViewer"
    members = ["allUsers"]
  }
}

resource "google_storage_bucket_iam_policy" "storage_getter_policy" {
  bucket      = google_storage_bucket.web_client.name
  policy_data = data.google_iam_policy.all_users_storage_getter.policy_data
}
