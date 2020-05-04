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

resource "google_compute_global_forwarding_rule" "client_ipv4" {
  name       = "web-client-lb-forwarding-rule-ipv4"
  target     = google_compute_target_https_proxy.client.self_link
  ip_address = google_compute_global_address.ipv4.address
  port_range = 443
}

resource "google_compute_global_forwarding_rule" "client_ipv6" {
  name       = "web-client-lb-forwarding-rule-ipv6"
  target     = google_compute_target_https_proxy.client.self_link
  ip_address = google_compute_global_address.ipv6.address
  port_range = 443
}

# TODO: enable this when you're confident the rest of the architecture is good.
# there's a limit to how many certs you can create/destroy
resource "google_compute_managed_ssl_certificate" "client" {
  provider = google-beta
  name     = "web-client-cert"
  managed {
    domains = [
      "${var.domain}",
      "www.${var.domain}",
    ]
  }
}

resource "google_compute_target_https_proxy" "client" {
  name             = "web-client-lb-http-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.client.self_link]
  url_map          = google_compute_url_map.urls.self_link
}

resource "google_compute_url_map" "urls" {
  name            = "web-client-lb-url-map"
  description     = "This just maps all requests to the backend bucket" # TODO: better desc
  default_service = google_compute_backend_bucket.lb_backend.self_link
}

resource "google_dns_record_set" "domain_root_ipv4" {
  name         = "${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "A"
  ttl          = 3600
  rrdatas      = [google_compute_global_address.ipv4.address]
}

resource "google_dns_record_set" "domain_root_ipv6" {
  name         = "${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "AAAA"
  ttl          = 3600
  rrdatas      = [google_compute_global_address.ipv6.address]
}

resource "google_storage_bucket" "web_client" {
  name = var.bucket_name

  bucket_policy_only = true # use Uniform bucket-level access (protected by IAM). Do not use ACLs. ACLs were a pre-IAM method of access control.

  # This is to prevent accidentally deleting the latest web client bundle, which
  # is the one that will be deployed.
  retention_policy {
    retention_period = 259200 # 3 days
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

data "google_iam_policy" "storage_getter" {
  binding {
    role    = "roles/storage.objects.get" # TODO: this is a permission. does it work as a role too, or do i need to make a custom role with just this permission?
    members = ["allUsers"]
  }
}

# TODO: add this to the web client bucket. first i want to deploy to see what the
# default roles assigned to the bucket are
resource "google_storage_bucket_iam_policy" "storage_getter_policy" {
  bucket      = google_storage_bucket.web_client.name
  policy_data = data.google_iam_policy.storage_getter.policy_data
}
