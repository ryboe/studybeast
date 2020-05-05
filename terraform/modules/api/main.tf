// api module

locals {
  connector_subnet_ip_range = "10.0.0.0/28" # the CIDR must be a /28 (four IP addresses)
  service_name              = "studybeast-api"
}

module "cloudrun" {
  source = "../cloudrun"

  container_registry_link = var.container_registry_link
  domain                  = "api.${var.domain}"
  dns_zone_name           = var.dns_zone_name
  image                   = var.image
  max_containers          = var.max_containers
  gcp_project_name        = var.gcp_project_name
  region                  = var.region
  service_name            = local.service_name
  service_account_email   = module.serviceaccount.email
}

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
  name          = "connector"
  ip_cidr_range = local.connector_subnet_ip_range
  network       = var.vpc_name
  region        = var.db_region # deploy the connector adjacent to the db
}
