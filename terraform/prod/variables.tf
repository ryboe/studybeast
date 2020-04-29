
variable "api_db_password" {
  description = "The db password used by the API service"
  type        = string
}

variable "api_image" {
  description = "The API image to deploy, e.g. gcr.io/studybeast-prod/api:c04d4a10095c6bd7ba2e0d40d6c11e36778dcef1"
  type        = string
}

variable "dbproxy_db_password" {
  description = "The db password used by the dbproxy service"
  type        = string
}
