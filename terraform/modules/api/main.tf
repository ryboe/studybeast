// api module

locals {
  service_name = "studybeast-api"
}

data "google_compute_subnetwork" "regional_subnet" {
  name   = var.vpc_name
  region = var.region
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
      service_account_name  = module.serviceaccount.email
      container_concurrency = "80"

      containers {
        image = var.image

        env {
          name  = "PORT"
          value = "8080"
        }
      }
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

resource "google_vpc_access_connector" "api_connector" {
  name          = "api-connector"
  ip_cidr_range = data.google_compute_subnetwork.regional_subnet.ip_cidr_range
  network       = var.vpc_name
  region        = var.db_region # deploy the connector adjacent to the db
}
