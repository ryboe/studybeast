// api module

locals {
  service_name = "studybeast-api"
}

resource "google_cloud_run_service" "api" {
  name       = local.service_name
  location   = var.region
  depends_on = [var.container_registry_link]

  traffic {
    percent         = var.traffic_percent
    latest_revision = true
  }

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10" # TODO: increase this to 1000 for prod
        "autoscaling.knative.dev/minScale" = "1"
      }
    }
    spec {
      containers {
        image = var.image
      }
      container_concurrency = "80"
      service_account_name  = module.serviceaccount.email
    }
  }

  autogenerate_revision_name = true
}

module "serviceaccount" {
  source = "../serviceaccount"

  name = local.service_name
  role = "roles/cloudsql.editor"
}

resource "google_cloud_run_domain_mapping" "default" {
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.project_name
  }

  spec {
    route_name = google_cloud_run_service.api.name
  }
}

resource "google_sql_user" "api_user" {
  name     = "api_user"
  instance = var.db_name
  password = var.db_password
}
