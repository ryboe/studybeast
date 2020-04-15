
data "google_compute_subnetwork" "regional_subnet" {
  name   = var.vpc_name
  region = var.region
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

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
      size  = 10 # smallest disk possible is 10 GB
      type  = "pd-ssd"
    }
  }

  metadata = {
    enable-oslogin = true
  }

  metadata_startup_script = templatefile("${path.module}/run_cloud_sql_proxy.sh", {
    "db_instance_name"    = var.db_instance_name,
    "service_account_key" = base64decode(google_service_account_key.key.private_key),
  })

  network_interface {
    network    = var.vpc_name
    subnetwork = data.google_compute_subnetwork.regional_subnet.self_link

    # The access_config block must be set for the instance to have a public IP,
    # even if it's empty.
    access_config {
      network_tier = "PREMIUM"
    }
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
  }

  service_account {
    email = google_service_account.dbproxy.email
    # These are OAuth scopes for the various Google Cloud APIs. We're already
    # using IAM roles (specifically, Cloud SQL Editor) to control what this
    # instance can and cannot do. We don't need another layer of OAuth
    # permissions on top of IAM, so we grant cloud-platform scope to the
    # instance. This is the maximum possible scope. It gives the instance
    # access to all Google Cloud APIs through OAuth.
    scopes = ["cloud-platform"]
  }

  # provisioner "file" {
  #   content     = base64decode(google_service_account_key.key.private_key)
  #   destination = "/key.json"
  # }
}

# TODO: turn these three resources into a service account module
resource "google_service_account" "dbproxy" {
  account_id  = "cloud-sql-proxy"
  description = "The service account used by Cloud SQL Proxy to connect to the db"
}

resource "google_project_iam_member" "sql_editor_role" {
  role   = "roles/cloudsql.editor"
  member = "serviceAccount:${google_service_account.dbproxy.email}"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.dbproxy.name
}
