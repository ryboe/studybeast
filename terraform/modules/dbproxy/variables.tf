// dbproxy module

variable "db_instance_name" {
  description = "The full instance name of the Cloud SQL db, e.g. my-project:us-central1:my-db"
  type        = string
}

variable "db_password" {
  description = "The db password used to connect to the Postgres db"
  type        = string
}

variable "db_user" {
  description = "The username of the db user"
  type        = string
}

variable "dns_zone_name" {
  description = "The Cloud DNS zone where the dbproxy subdomain will be created"
  type        = string
}

variable "domain" {
  description = <<-EOT
    The domain under which the dbproxy subdomain will be created, e.g. example.com
    for dbproxy.example.com
  EOT
  type        = string
}

variable "machine_type" {
  description = "The type of VM you want, e.g. f1-micro, c2-standard-4"
  type        = string
}

variable "region" {
  description = "The region that the proxy instance will run in (e.g. us-central1)"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC that the proxy instance will run in"
  type        = string
}

variable "zone" {
  description = "The zone where the VM will be created, e.g. us-centra1-a"
  type        = string
}
