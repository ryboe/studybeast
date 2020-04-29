terraform {
  required_version = "~> 0.12.24"
  required_providers {
    google      = "~> 3.19.0"
    google-beta = "~> 3.19.0"
    random      = "~> 2.2.1"
    tfe         = "~> 0.16.0"
  }
  backend "remote" {
    organization = "studybeast-org"
    workspaces {
      name = "studybeast-prod"
    }
  }
}

locals {
  api_db_user            = "api_user"
  db_disk_size           = 10            # GB, use at least 1700 for prod
  db_instance_type       = "db-f1-micro" # TODO: use db-custom for prod
  db_proxy_instance_type = "f1-micro"
  domain                 = "ryanboehning.com"
  gcp_project_name       = "studybeast-prod"
  gcp_region             = "us-central1"
  gcp_zone               = "us-central1-b"
  vpc_name               = "main-vpc"
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

module "vpc" {
  # We need the beta provider to enable setting a private IP for the db.
  providers = {
    google = google-beta # override the default google provider with the google-beta provider
  }
  source = "../modules/vpc"
  name   = local.vpc_name
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
  user          = local.api_db_user
  password      = var.proxy_db_password # this is a variable because it's a secret. it's stored here: https://app.terraform.io/app/studybeast/workspaces/prod/variables
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

  db_instance_name = module.db.connection_name # e.g. my-project:us-central1:my-db
  machine_type     = local.db_proxy_instance_type
  region           = local.gcp_region
  zone             = local.gcp_zone

  # Even though module.vpc.name is identical to local.vpc_name, passing
  # module.vpc.name prevents the proxy from being created before the VPC. We
  # can't create a proxy instance until we have a VPC to put it in.
  vpc_name = module.vpc.name
}

module "api" {
  source = "../modules/api"

  container_registry_link = google_container_registry.main
  db_name                 = module.db.name
  db_password             = var.api_db_password
  domain                  = "api.${local.domain}"
  image                   = var.api_image
  project_name            = local.gcp_project_name
  region                  = local.gcp_region # where the API will be deployed
  db_region               = module.db.region # where the db is located
  vpc_link                = module.vpc.self_link
}

resource "google_container_registry" "main" {}
