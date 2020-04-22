// api module

variable "db_name" {
  description = "The name of the database that the API will connect to"
  type        = string
}

variable "db_password" {
  description = "The db password the API will use to connect to the db"
  type        = string
}

variable "project_name" {
  description = "The name of the GCP project"
  type        = string
}

variable "traffic_percent" {
  description = "The percentage of traffic to send to this revision of the image"
  default     = 100
  type        = number
}

variable "region" {
  description = "The region where the containers will run on Cloud Run (e.g. us-central1)"
  type        = string
}
