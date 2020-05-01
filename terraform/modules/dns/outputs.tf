// dns module

output "zone_name" {
  description = <<-EOT
    The Cloud DNS managed zone name. Other modules need this name to create their DNS
    records.
  EOT
  value       = google_dns_managed_zone.public.name
}
