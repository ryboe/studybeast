// cloudrun module

variable "container_registry_link" {
  description = "The registry that Cloud Run will pull the image from"
  type        = any
}

variable "domain" {
  description = "The domain under which the redirector image will run, e.g. 'ryanboehning.com'"
  type        = string
}

variable "dns_zone_name" {
  description = "The DNS zone where the record for the domain will be inserted"
  type        = string
}

variable "image" {
  description = "The container image you want to run"
  type        = string
}

variable "max_containers" {
  description = "The maximum number of containers to run, from 1-1000"
  type        = number
}

variable "gcp_project_name" {
  description = "The id of the GCP project the Cloud Run service will be created in"
  type        = string
}

variable "region" {
  description = "The region where the containers will run, e.g. us-central1"
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service, e.g. studybeast-api"
  type        = string
}

variable "service_account_email" {
  default     = null
  description = "The email address of the service account to associate with the service you're running"
  type        = string
}
