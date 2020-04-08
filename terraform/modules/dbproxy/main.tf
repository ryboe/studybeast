
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
    email = var.service_account_email
    # These are OAuth scopes for the various Google Cloud APIs. We're already
    # using IAM roles (specifically, Cloud SQL Editor) to control what this
    # instance can and cannot do. We don't need another layer of OAuth
    # permissions on top of IAM, so we grant cloud-platform scope to the
    # instance. This is the maximum possible scope. It gives the instance
    # access to all Google Cloud APIs through OAuth.
    scopes = ["cloud-platform"]
  }
}

// need to add network tag to instance
// need to create firewall rule to allow SSH to instance
// need to update terraform provider google to 3.16.0
