// api module

variable "container_registry_link" {
  description = "The registry that Cloud Run will pull the API image from"
  type        = any
}

variable "db_name" {
  description = "The name of the database that the API will connect to, e.g. main-primary"
  type        = string
}

variable "db_user" {
  description = "The Postgres user account that the API will connect to"
  type        = string
}

variable "db_password" {
  description = "The db password the API will use to connect to the db"
  type        = string
}

variable "db_region" {
  description = "The region where the db is deployed, e.g. us-central1"
  type        = string
}

variable "domain" {
  description = "The domain under which the API image will run, e.g. 'ryanboehning.com'"
  type        = string
}

variable "dns_zone_name" {
  description = "The Cloud DNS zone where the api subdomain CNAME record will be created"
  type        = string
}

variable "gcp_project_name" {
  description = "The name of the GCP project"
  type        = string
}

variable "image" {
  description = "The API container image you want to deploy, e.g. gcr.io/studybeast-prod/api"
  type        = string
}

variable "max_containers" {
  description = "The maximum number of containers to run, from 1-1000"
  type        = number
}

variable "region" {
  description = "The region where the API containers will run, e.g. us-central1"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC where the connector will be deployed, e.g. main-vpc"
  type        = string
}
