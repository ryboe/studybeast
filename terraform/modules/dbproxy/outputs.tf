
output "dbproxy_service_account_expiration_date" {
  description = "The UTC date when the service account key will expire"
  value       = google_service_account_key.key.valid_before
}
