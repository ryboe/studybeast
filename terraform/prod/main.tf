terraform {
  required_version = "~> 0.12.24"
  required_providers {
    google      = "~> 3.20.0"
    google-beta = "~> 3.20.0"
    random      = "~> 2.2.1"
    tfe         = "~> 0.16.1"
  }
  backend "remote" {
    organization = "studybeast-org"
    workspaces {
      name = "studybeast-prod"
    }
  }
}

locals {
  api_db_user                         = "api_user"
  db_disk_size                        = 10            # GB, use at least 1700 for prod
  db_instance_type                    = "db-f1-micro" # TODO: use db-custom for prod
  dbproxy_db_user                     = "dbproxy_user"
  dbproxy_instance_type               = "g1-small"
  domain                              = "ryanboehning.com"
  domain_ownership_verification_token = "\"google-site-verification=t9PY56lYU-o4wC77U_eR7trEocsB-lAxFHP3epR0BUM\"" # must include quotes. must escape the quotes
  gcp_project_name                    = "studybeast-prod"
  gcp_region                          = "us-central1"
  gcp_zone                            = "us-central1-b"
  vpc_name                            = "main-vpc"
  web_client_bucket_name              = "${local.gcp_project_name}-web-client-bucket"
}

provider "google" {
  project = local.gcp_project_name
  region  = local.gcp_region
  zone    = local.gcp_zone
}

provider "google-beta" {
  project = local.gcp_project_name
  region  = local.gcp_region
  zone    = local.gcp_zone
}

module "api" {
  source = "../modules/api"

  container_registry_link = google_container_registry.main
  db_name                 = module.db.name
  db_password             = var.api_db_password
  db_region               = module.db.region # where the db is located
  db_user                 = local.api_db_user
  dns_zone_name           = module.dns.zone_name
  domain                  = local.domain
  gcp_project_name        = local.gcp_project_name
  image                   = var.api_image
  max_containers          = "10"             # TODO: increase this to 1000 for prod
  region                  = local.gcp_region # where the API will be deployed
  vpc_name                = module.vpc.name
}

module "cloudrun" {
  source = "../modules/cloudrun"

  container_registry_link = google_container_registry.main
  domain                  = local.domain
  dns_zone_name           = module.dns.zone_name
  image                   = var.redirector_image
  max_containers          = "10" # TODO: increase this to 1000 for prod
  gcp_project_name        = local.gcp_project_name
  region                  = local.gcp_region
  service_name            = "studybeast-redirector"
}

module "db" {
  # TODO: delete this block when postgres 12 is out of beta
  providers = {
    google = google-beta # override the default google provider with the google-beta provider
  }
  source = "../modules/db"

  # disk_size = 1700 # minimum GB to get max IOPS
  # instance_type = "db-custom-8-32768" # 8 cores, 32 GB RAM, min size to get max network bandwidth from google
  disk_size     = local.db_disk_size
  instance_type = local.db_instance_type
  vpc_link      = module.vpc.self_link

  # There's a dependency relationship between the db and the VPC that
  # terraform can't figure out. The db instance depends on the VPC because it
  # uses a private IP from a block of IPs defined in the VPC. If we just giving
  # the db a public IP, there wouldn't be a dependency. The dependency exists
  # because we've configured private services access. We need to explicitly
  # specify the dependency here. For details, see the note in the docs here:
  #   https://www.terraform.io/docs/providers/google/r/sql_database_instance.html#private-ip-instance
  db_depends_on = module.vpc.private_vpc_connection
}

module "dbproxy" {
  source = "../modules/dbproxy"

  db_instance_name = module.db.instance_name # e.g. my-project:us-central1:my-db
  db_password      = var.dbproxy_db_password
  db_user          = local.dbproxy_db_user
  dns_zone_name    = module.dns.zone_name
  domain           = local.domain
  machine_type     = local.dbproxy_instance_type
  region           = local.gcp_region
  zone             = local.gcp_zone

  # Even though module.vpc.name is identical to local.vpc_name, passing
  # module.vpc.name prevents the proxy from being created before the VPC. We
  # can't create a proxy instance until we have a VPC to put it in.
  vpc_name = module.vpc.name
}

module "dns" {
  source = "../modules/dns"

  domain = local.domain

  # The quotation marks are a required part of the token, so we must escape them.
  # TODO: make this a local (do we need to triple escape the quotes \\\")?
  domain_ownership_verification_token = local.domain_ownership_verification_token
}

module "vpc" {
  # We need the beta provider to enable setting a private IP for the db.
  providers = {
    google = google-beta # override the default google provider with the google-beta provider
  }
  source = "../modules/vpc"
  name   = local.vpc_name
}

module "webclient" {
  source = "../modules/webclient"

  bucket_name   = local.web_client_bucket_name
  domain        = "www.${local.domain}"
  dns_zone_name = module.dns.zone_name
}

# We don't specify the region, so the registry defaults to being global, not
# regional (gcr.io vs us.gcr.io).
resource "google_container_registry" "main" {}
