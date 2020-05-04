// frontend module

variable "bucket_name" {
  description = <<-EOT
    The bucket that holds the static web app we want to serve. The name must be unique among
    all buckets on GCP
  EOT
  type        = string
}

variable "domain" {
  description = "The domain that will serve the web client, e.g. example.com"
  type        = string
}

variable "dns_zone_name" {
  description = "The Cloud DNS zone where the domain and www subdomain are managed"
  type        = string
}
