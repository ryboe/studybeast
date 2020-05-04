// api module

locals {
  connector_subnet_ip_range = "10.0.0.0/28" # the CIDR must be a /28 (four IP addresses)
  service_name              = "studybeast-api"
  max_containers            = "10" # TODO: increase this to 1000 for prod
}

# We need a Cloud Run Invoker role for all users to make the Cloud Run service
# public.
data "google_iam_policy" "cloud_run_invoker_role" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

resource "google_cloud_run_domain_mapping" "default" {
  provider = google-beta
  location = var.region
  name     = "api.${var.domain}"

  metadata {
    namespace = var.project_name
  }

  spec {
    route_name = google_cloud_run_service.api.name
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
        "autoscaling.knative.dev/maxScale" = local.max_containers
      }
    }
    spec {
      service_account_name  = module.serviceaccount.email
      container_concurrency = "80" # max is 80 connections per container

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
  location = google_cloud_run_service.api.location
  project  = google_cloud_run_service.api.project
  service  = google_cloud_run_service.api.name

  policy_data = data.google_iam_policy.cloud_run_invoker_role.policy_data
}

# Create the api subdomain (e.g. api.example.com).
resource "google_dns_record_set" "api" {
  name         = "api.${var.domain}."
  managed_zone = var.dns_zone_name
  type         = "CNAME"
  ttl          = 300 # 5 min  TODO: bump this up to 24 hours if it works
  rrdatas      = ["ghs.googlehosted.com."]
}

# Create a Postgres user account, so the API can connect to the db.
resource "google_sql_user" "api_user" {
  name     = "api_user"
  instance = var.db_name
  password = var.db_password
}

resource "google_vpc_access_connector" "connector" {
  name          = "connector"
  ip_cidr_range = local.connector_subnet_ip_range
  network       = var.vpc_name
  region        = var.db_region # deploy the connector adjacent to the db
}

module "serviceaccount" {
  source = "../serviceaccount"

  name = local.service_name
  role = "roles/cloudsql.editor"
}
