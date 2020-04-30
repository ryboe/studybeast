// vpcconnector module

# We need a dedicated /28 subnet to run the VPC connector in.
resource "google_compute_subnetwork" "vpc_connector_subnet" {
  name        = "vpc-connector-subnet"
  description = "The four IP address subnet where the VPC access connector will run"
  network     = var.vpc_link

  ip_cidr_range            = "10.0.0.0/28"
  private_ip_google_access = true # TODO: can this be false?
}

resource "google_vpc_access_connector" "connector" {
  name          = "connector"
  project       = var.project_name # We have to explicity pass the project ID for some stupid reason.
  ip_cidr_range = google_compute_subnetwork.vpc_connector_subnet.ip_cidr_range
  network       = "main-vpc" # TODO: change this to a reference
  region        = var.region # deploy the connector adjacent to the db
}
