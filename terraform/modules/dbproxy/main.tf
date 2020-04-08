
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
      size  = 10 # smallest size disk
      type  = "pd-ssd"
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  # TODO: docker run whatever
  # metadata_startup_script {

  # }

  network_interface {
    subnetwork = var.subnet

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
    email  = var.service_account_email
    scopes = ["sql-admin"]
  }
}
