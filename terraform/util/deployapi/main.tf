// util/deployapi

module "api" {
  source = "../../modules/api"

  image                   = "gcr.io/${var.project_name}/api"
  container_registry_link = google_container_registry.main
  region                  = var.region
  domain                  = "ryanboehning.com" # TODO: change to the final domain
  db_name                 = var.db_name
  db_password             = var.db_password
  project_name            = var.project_name
}

resource "google_container_registry" "main" {}
