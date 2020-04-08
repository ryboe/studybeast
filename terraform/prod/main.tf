terraform {
  required_version = "~> 0.12.24"
  required_providers {
    tfe         = "~> 0.15.1"
    google      = "~> 3.16.0"
    google-beta = "~> 3.16.0"
  }
  backend "remote" {}
}

locals {
  gcp_project_name = "studygoose-prototype"
  gcp_region       = "us-central1"
  gcp_zone         = "us-central1-b"
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

  name        = "main-vpc"
  description = "The main StudyGoose VPC that holds all the instances"
}

module "db" {
  # TODO: delete this block when postgres 12 is out of beta
  providers = {
    google = google-beta # override the default google provider with the google-beta provider
  }
  source = "../modules/db"

  # disk_size = 1700 # minimum GB to get max IOPS
  # instance_type = "db-custom-8-32768" # 8 cores, 32 GB RAM, min size to get max network bandwidth from google
  disk_size     = 10                  # TODO: use 1700 for prod
  instance_type = "db-f1-micro"       # TODO: use db-custom for prod
  password      = var.api_db_password # this is a variable because it's a secret. it's stored here: https://app.terraform.io/app/jabronesoft/workspaces/terraform-cloud-studies/variables
  user          = "api_user"
  vpc_name      = module.vpc.name
  vpc_uri       = module.vpc.uri

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

  machine_type          = "f1-micro"
  service_account_email = "${jsondecode(var.cloud_sql_proxy_service_account_key)["client_email"]}"
  subnet                = module.vpc.name
  zone                  = var.gcp_zone
}
