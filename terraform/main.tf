terraform {
  required_version = "~> 0.12.24"
  required_providers {
    tfe         = "~> 0.15.0"
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
  name                    = "sg_vpc"
  description             = "The studygoose prod VPC."
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
}

variable "project_name" {
  default     = "studygoose-prototype"
  description = "The main GCP project name."
  type        = string
}

variable "default_region" {
  default     = "us-central1"
  description = "The default GCP region (us-central1 is in Iowa) for creating resources."
  type        = string
}

variable "default_zone" {
  default     = "us-central1-b"
  description = "The default GCP zone for creating zonal resources, like VMs."
  type        = string
}
