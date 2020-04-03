
variable "api_db_password" {
  description = "The db password used by the API service"
  type        = string
}

variable "gcp_project_name" {
  description = "The main GCP project name"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for creating resources (us-central1 is in Iowa)"
  type        = string
}

variable "gcp_zone" {
  description = "The default GCP zone for creating zonal resources, like VMs"
  type        = string
}