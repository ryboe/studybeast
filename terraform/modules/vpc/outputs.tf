output "name" {
  description = "The name of the VPC" # TODO: better desc
  value       = google_compute_network.vpc.name
}

output "private_vpc_connection" {
  description = "The private VPC connection" # TODO: better desc
  value       = google_service_networking_connection.private_vpc_connection
}

output "uri" {
  description = "The URI of the VPC" # TODO: better desc
  value       = google_compute_network.vpc.self_link
}
