
output "instance_name" {
  description = "The full db name used by Cloud SQL Proxy, e.g. my-project:us-central1:my-db"
  value       = google_sql_database_instance.main_primary.connection_name
}

output "name" {
  description = "The name of the db that's created"
  value       = google_sql_database_instance.main_primary.name
}

output "region" {
  description = "The region where the db is deployed"
  value       = google_sql_database_instance.main_primary.region
}
