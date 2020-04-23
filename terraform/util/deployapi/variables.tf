// util/deployapi

variable "db_name" {
  description = "The name of the db instance that the API will connect to"
  type        = string
}

variable "db_password" {
  description = "The password for the db the API will connect to"
  type        = string
}

variable "project_name" {
  description = "The name of the GCP project in which the service will run"
  type        = string
}

variable "region" {
  description = "The region where the Cloud Run service will run"
  type        = string
}
