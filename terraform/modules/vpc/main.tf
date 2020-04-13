
resource "google_compute_network" "vpc" {
  name                    = var.name
  description             = var.description
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true

  depends_on = [google_project_service.enable_iam_api]

  # lifecycle {
  #   prevent_destroy = true
  # }
}

# We need to allocate an IP block for private IPs. We want everything in the VPC
# to have a private IP. This improves security and latency, since requests to
# private IPs are routed through Google's network, not the Internet.
resource "google_compute_global_address" "private_ip_block" {
  name         = "private-ip-block"
  description  = "A block of private IP addresses that are accessible only from within the VPC."
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  # We don't specify a address block because Google will automatically assign one for us.
  prefix_length = 20 # ~4k IPs
  network       = google_compute_network.vpc.self_link
}

# This enables private services access. This makes it possible for instances
# within the VPC and Google services to communicate exclusively using internal
# IP addresses. I don't really understand this, but I know it's important. You
# can read the details here:
#   https://cloud.google.com/sql/docs/postgres/configure-private-services-access
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

resource "google_project_service" "enable_iam_api" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true

  depends_on = [
    google_project_service.enable_cloud_resource_manager_api
  ]
}

resource "google_project_service" "enable_cloud_resource_manager_api" {
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "enable_compute_engine_api" {
  service                    = "compute.googleapis.com"
  disable_dependent_services = true

  # terraform can't enable APIs without the Cloud Resource Manager API first
  # being enabled.
  depends_on = [
    google_project_service.enable_cloud_resource_manager_api
  ]
}
