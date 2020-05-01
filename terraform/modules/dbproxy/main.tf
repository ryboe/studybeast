// dbproxy

data "google_compute_subnetwork" "regional_subnet" {
  name   = var.vpc_name
  region = var.region
}

# We reserve a public IP so that we can assign it to the dbproxy subdomain. Then
# the proxy VM can be accessed at dbproxy.example.com.
resource "google_compute_address" "public_static_ip" {
  name         = "dbproxy-public-static-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

resource "google_compute_instance" "db_proxy" {
  name                      = "db-proxy"
  description               = <<-EOT
    A public-facing instance that proxies traffic to the database. This allows
    the db to only have a private IP address, but still be reachable from
    psql or Cloud Run containers.
  EOT
  machine_type              = var.machine_type
  zone                      = var.zone
  desired_status            = "RUNNING"
  allow_stopping_for_update = true

  tags = ["ssh-enabled"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = 10 # smallest disk possible is 10 GB
      type  = "pd-ssd"
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/run_cloud_sql_proxy.tpl", {
    "db_instance_name"    = var.db_instance_name,
    "service_account_key" = module.serviceaccount.private_key,
  })

  network_interface {
    network    = var.vpc_name
    subnetwork = data.google_compute_subnetwork.regional_subnet.self_link

    # The access_config block must be set for the instance to have a public IP,
    # even if it's empty.
    access_config {
      nat_ip       = google_compute_address.public_static_ip.address
      network_tier = "PREMIUM"
    }
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    email = module.serviceaccount.email
    # These are OAuth scopes for the various Google Cloud APIs. We're already
    # using IAM roles (specifically, Cloud SQL Editor) to control what this
    # instance can and cannot do. We don't need another layer of OAuth
    # permissions on top of IAM, so we grant cloud-platform scope to the
    # instance. This is the maximum possible scope. It gives the instance
    # access to all Google Cloud APIs through OAuth.
    scopes = ["cloud-platform"]
  }
}

# Create the dbproxy subdomain (e.g. dbproxy.example.com).
resource "google_dns_record_set" "dbproxy" {
  name         = "dbproxy.${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "A"
  ttl          = 300 # 5 min
  rrdatas      = [google_compute_address.public_static_ip.address]
}

resource "google_sql_user" "dbproxy_user" {
  instance = split(":", var.db_instance_name)[2] # my-project:us-central1:my-db -> my-db
  name     = var.db_user
  password = var.db_password
}

module "serviceaccount" {
  source = "../serviceaccount"

  name = "cloud-sql-proxy"
  role = "roles/cloudsql.editor"
}
