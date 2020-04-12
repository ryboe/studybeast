terraform {
  required_version = "~> 0.12.24"
  required_providers {
    tfe         = "~> 0.15.1"
    google      = "~> 3.16.0"
    google-beta = "~> 3.16.0"
    random      = "~> 2.2"
  }
  backend "remote" {
    organization = "studybeast-org"
    workspaces {
      name = "studybeast-prod"
    }
  }
}
