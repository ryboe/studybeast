// api module

locals {
  connector_subnet_ip_range = "10.0.0.0/28" # the CIDR must be a /28 (four IP addresses)
  service_name              = "studybeast-api"
  subdomain                 = "api.${var.domain}"
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
  location = var.region
  name     = local.subdomain

  metadata {
    namespace = var.gcp_project_name
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

resource "google_dns_record_set" "cname" {
  name         = "${local.subdomain}."
  managed_zone = var.dns_zone_name
  type         = "CNAME"
  ttl          = 300 # 5 min  TODO: bump this up to 24 hours if it works
  rrdatas      = ["ghs.googlehosted.com."]
}


# module "cloudrun" {
#   source = "../cloudrun"

#   container_registry_link = var.container_registry_link
#   domain                  = "api.${var.domain}"
#   dns_zone_name           = var.dns_zone_name
#   image                   = var.image
#   max_containers          = var.max_containers
#   gcp_project_name        = var.gcp_project_name
#   region                  = var.region
#   service_name            = local.service_name
#   service_account_email   = module.serviceaccount.email
# }

# module "api" {
#   source = "../modules/api"

#   container_registry_link = google_container_registry.main
#   db_name                 = module.db.name
#   db_password             = var.api_db_password
#   db_region               = module.db.region # where the db is located
#   db_user                 = local.api_db_user
#   dns_zone_name           = module.dns.zone_name
#   domain                  = local.domain
#   gcp_project_name        = local.gcp_project_name
#   image                   = var.api_image
#   max_containers          = "10"             # TODO: increase this to 1000 for prod
#   region                  = local.gcp_region # where the API will be deployed
#   vpc_name                = module.vpc.name
# }

module "serviceaccount" {
  source = "../serviceaccount"

  name = local.service_name
  role = "roles/cloudsql.editor"
}

# Create a Postgres user account, so the API can connect to the db.
resource "google_sql_user" "api_user" {
  name     = "api_user"
  instance = var.db_name
  password = var.db_password
}

resource "google_vpc_access_connector" "connector" {
  provider      = google-beta
  name          = "connector"
  ip_cidr_range = local.connector_subnet_ip_range
  network       = var.vpc_name
  region        = var.db_region # deploy the connector adjacent to the db
}
