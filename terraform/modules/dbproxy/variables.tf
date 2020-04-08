
variable "machine_type" {
  description = "The type of VM you want, e.g. f1-micro, c2-standard-4"
  type        = string
}

variable "service_account_email" {
  description = "The email address associated with the service account that the proxy will use, e.g. cloud-sql-proxy@studygoose-prototype.iam.gserviceaccount.com"
  type        = string
}

variable "subnet" {
  description = "The name of the VPC subnet that the proxy instance will run in"
  type        = string
}

variable "zone" {
  description = "The zone where the VM will be created, e.g. us-centra1-a"
  type        = string
}
