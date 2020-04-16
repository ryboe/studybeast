
output "email" {
  value = google_service_account.account.email
}

output "base64_encoded_private_key" {
  value = google_service_account_key.key.private_key
}
