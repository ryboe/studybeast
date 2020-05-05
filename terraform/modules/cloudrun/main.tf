// cloudrun module

# We need a Cloud Run Invoker role for all users to make the Cloud Run service
# public.
data "google_iam_policy" "cloud_run_invoker_role" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

# Make the naked domain point to the redirector container. That container will
# redirect the request to www.ryanboehning.com. DNS will direct those requests
# to the IP of the load balancer.
resource "google_dns_record_set" "cname" {
  name         = "${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "CNAME"
  ttl          = 300 # 5 min  TODO: bump this up to 24 hours if it works
  rrdatas      = ["ghs.googlehosted.com."]
}

resource "google_cloud_run_domain_mapping" "default" {
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.gcp_project_name
  }

  spec {
    route_name = google_cloud_run_service.main.name
  }
}

resource "google_cloud_run_service" "main" {
  name       = var.service_name
  location   = var.region
  depends_on = [var.container_registry_link]

  traffic {
    percent         = 100
    latest_revision = true
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = var.max_containers
      }
    }
    spec {
      service_account_name  = var.service_account_email # if this var is null, Cloud Run will use the default service account
      container_concurrency = "80"                      # max is 80 connections per container

      containers {
        image = var.image
      }
    }
  }

  autogenerate_revision_name = true
}

# We make the Cloud Run service public by assigning the Cloud Run Invoker role
# to all users.
resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.main.location
  project  = google_cloud_run_service.main.project
  service  = google_cloud_run_service.main.name

  policy_data = data.google_iam_policy.cloud_run_invoker_role.policy_data
}
