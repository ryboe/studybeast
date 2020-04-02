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
  description             = "The StudyGoose prod VPC."
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

resource "google_sql_database" "main" {
  name     = "main"
  instance = google_sql_database_instance.main_primary.name # instance name will be generated by google
}

resource "google_sql_database_instance" "main_primary" {
  provider         = google-beta
  database_version = "POSTGRES_12"

  settings {
    tier              = "db-custom-8-32768" # 8 cores, 32 GB RAM, min size to get max network bandwidth from google
    availability_type = "REGIONAL"          # storage distributed across zones for high availability
    disk_size         = "1700"              # 1.7 TB, min size to get max IOPS from google

    backup_configuration {
      enabled    = true
      start_time = "02:00"
    }

    # number of autovacuum processes. the db is not CPU bound at all. it's IO bound.
    # we can trade some CPU for better IO (from reading fewer dead rows)
    database_flags {
      name  = "autovacuum_max_workers"
      value = "8" # default is 3
    }

    # a checkpoint means shared buffers are flushed to disk. can create a
    # lot of IO load. spread the IO load over 0.7 * 5min = 3.5min. 5min
    # is the checkpoint timeout. we can be more aggressive about lightening
    # the load of a checkpoint because we have an SSD.
    database_flags {
      name  = "checkpoint_completion_target"
      value = "0.7" # default is 0.5
    }

    # prevent four kinds of db read/write errors
    database_flags {
      name  = "default_transaction_isolation"
      value = "serializable"
    }

    # max memory usable by vacuum, create index, or alter table add foreign key.
    # unit is KB
    database_flags {
      name  = "maintenance_work_mem"
      value = "262144" # default is 65536 (64 MB). increase 4X to 256 MB
    }

    # query planner's estimate for cost of a disk access
    database_flags {
      name  = "random_page_cost"
      value = "1.1" # default is 4. should be 1.1 for SSDs
    }

    # per-session memory allocated for creation of temporary tables.
    # not super useful, but cost of raising it without using it is negligible.
    database_flags {
      name  = "temp_buffers"
      value = "8192" # unit is number of 4KB disk blocks. raise to 8192 (32 MB). default is 1024 (4 MB)
    }

    # max amount of memory a query can use. unit is KB.
    database_flags {
      name  = "work_mem"
      value = "16384" # default is 4096 (4 MB). increase 4X to 16 MB
    }

    ip_configuration {
      private_network = google_compute_network.sg_vpc.self_link
    }

    maintenance_window {
      day  = 6 # saturday
      hour = 9 # 2am PST, 5am EST, 9am UTC
    }
  }
}

resource "google_sql_user" "api_user" {
  name     = "api-user"
  instance = google_sql_database_instance.main_primary.name
  password = var.api_user_db_password
}

variable "api_user_db_password" {
  description = "The db password used by the API servers to connect to the main Postgers db."
  type        = string
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
