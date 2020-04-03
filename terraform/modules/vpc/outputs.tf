output "name" {
  value = google_compute_network.vpc.name
}

output "private_vpc_connection" {
  value = google_service_networking_connection.private_vpc_connection
}

output "uri" {
  value = google_compute_network.vpc.self_link
}
