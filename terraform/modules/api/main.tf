// api module

locals {
  service_name = "studybeast-api"
}

data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
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
      }
    }
    spec {
      service_account_name  = module.serviceaccount.email
      container_concurrency = "80"

      containers {
        image = var.image
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

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.api.location
  project  = google_cloud_run_service.api.project
  service  = google_cloud_run_service.api.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_sql_user" "api_user" {
  name     = "api_user"
  instance = var.db_name
  password = var.db_password
}

module "vpcconnector" {
  source = "../vpcconnector"

  region   = var.db_region
  vpc_link = var.vpc_link
}
