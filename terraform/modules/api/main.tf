// api module

resource "google_cloud_run_service" "api" {
  name       = "studybeast-api"
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
        image = "gcr.io/studybeast-prod/api"
      }
      container_concurrency = "80"
      service_account_name  = module.serviceaccount.email
    }
  }

  autogenerate_revision_name = true
}

module "serviceaccount" {
  source = "../serviceaccount"

  name = "studybeast-api"
  role = "roles/cloudsql.editor"
}

resource "google_cloud_run_domain_mapping" "default" {
  location = var.region
  name     = "ryanboehning.com"

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

  # api_sql_user_depends_on is the same value as db_name. Passing the same value
  # twice is dumb, but we have to be explicit about the dependency with
  # depends_on, otherwise terraform will not teardown the cluster cleanly. This
  # is probably a bug in the terraform-cloud-google provider.
  depends_on = [var.api_sql_user_depends_on]
}
