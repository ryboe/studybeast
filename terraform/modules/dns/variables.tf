// dns module

variable "domain" {
  description = "The naked domain that will be assigned to the managed zone (e.g. ryanboehing.com)"
  type        = string
}

variable "domain_ownership_verification_token" {
  description = <<-EOT
    When you create a GCP organization, you need to verify ownership of a domain. You
    do this by creating a TXT record with a token provided by Google.
  EOT
  type        = string
}
