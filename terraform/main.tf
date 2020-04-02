terraform {
  required_version = "~> 0.12.24"
  required_providers {
    tfe         = "~> 0.15.0"
    google      = "~> 3.15.0"
    google-beta = "~> 3.15.0"
  }
  backend "remote" {}
}

provider "google" {
  project = var.project_name
  region  = var.default_region
  zone    = var.default_zone
}

provider "google-beta" {
  project = var.project_name
  region  = var.default_region
  zone    = var.default_zone
}

resource "google_compute_network" "sg_vpc" {
  name                    = "sg-vpc"
  description             = "The studygoose prod VPC."
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_icmp" {
  name          = "default-allow-icmp"
  description   = "Allow ICMP ingress for all instances. This makes everything ping-able."
  network       = google_compute_network.sg_vpc.name
  direction     = "INGRESS"
  priority      = 65534 # second lowest priority. this will be applied widely. setting a low priority makes it easy to be override.
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow_postgres_tcp" {
  name        = "allow-postgres-tcp"
  description = "All TCP ingress on port 5432. This is intended to be applied to the Cloud SQL Postgres db."
  network     = google_compute_network.sg_vpc.name
  direction   = "INGRESS"
  priority    = 100
  source_tags = ["api"]
  target_tags = ["db"]

  allow {
    protocol = "tcp"
    ports    = [5432]
  }
}

variable "project_name" {
  description = "The main GCP project name."
  type        = string
  default     = "studygoose-prototype"
}

variable "default_region" {
  description = "The default GCP region (us-central1 is in Iowa) for creating resources."
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "The default GCP zone for creating zonal resources, like VMs."
  type        = string
  default     = "us-central1-b"
}
