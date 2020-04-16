# terraform {
#   required_version = "~> 0.12.24"
#   required_providers {
#     tfe         = "~> 0.15.1"
#     google      = "~> 3.17.0"
#     google-beta = "~> 3.17.0"
#     random      = "~> 2.2"
#   }
#   backend "remote" {}
# }

# locals {
#   cluster_name   = lower(var.developer_first_name)
#   gcp_org_id     = "1018837703108" # TODO: replace with real org ID. currently using Boehning Industries org ID. replace with real studybeast org ID
#   gcp_project_id = "studybeast-dev-${local.developer_first_name}-${random_string.six_lowercase_alphanumeric_chars.result}"
#   gcp_region     = "us-central1"
#   gcp_zone       = "us-central1-b"
#   vpc_name       = "main-vpc"
# }

# provider "google" {
#   project = local.gcp_project_id
#   region  = local.gcp_region
#   zone    = local.gcp_zone
# }

# provider "google-beta" {
#   project = local.gcp_project_id
#   region  = local.gcp_region
#   zone    = local.gcp_zone
# }

# module "vpc" {
#   # We need the beta provider to enable setting a private IP for the db.
#   providers = {
#     google = google-beta # override the default google provider with the google-beta provider
#   }
#   source = "../modules/vpc"

#   name        = local.vpc_name
#   description = "The main StudyBeast VPC that holds all the instances"
# }

# module "db" {
#   # TODO: delete this block when postgres 12 is out of beta
#   providers = {
#     google = google-beta # override the default google provider with the google-beta provider
#   }
#   source = "../modules/db"

#   # disk_size = 1700 # minimum GB to get max IOPS
#   # instance_type = "db-custom-8-32768" # 8 cores, 32 GB RAM, min size to get max network bandwidth from google
#   disk_size     = 10                  # TODO: use 1700 for prod
#   instance_type = "db-f1-micro"       # TODO: use db-custom for prod
#   password      = var.api_db_password # this is a variable because it's a secret. it's stored here: https://app.terraform.io/app/studybeast/workspaces/studybeast-dev-ryan/variables
#   user          = "api_user"
#   vpc_name      = module.vpc.name
#   vpc_uri       = module.vpc.uri

#   # There's a dependency relationship between the db and the VPC that
#   # terraform can't figure out. The db instance depends on the VPC because it
#   # uses a private IP from a block of IPs defined in the VPC. If we just giving
#   # the db a public IP, there wouldn't be a dependency. The dependency exists
#   # because we've configured private services access. We need to explicitly
#   # specify the dependency here. For details, see the note in the docs here:
#   #   https://www.terraform.io/docs/providers/google/r/sql_database_instance.html#private-ip-instance
#   db_depends_on = module.vpc.private_vpc_connection
# }

# # module "dbproxy" {
# #   source = "../modules/dbproxy"

# #   machine_type          = "f1-micro"
# #   service_account_email =
# #   subnet                = local.vpc_name
# #   zone                  = local.gcp_zone
# # }

# resource "google_project" "project" {
#   name                = local.gcp_project_id
#   project_id          = local.gcp_project_id
#   org_id              = local.gcp_org_id
#   auto_create_network = false # don't create a default VPC. we'll manually create the VPC
# }
