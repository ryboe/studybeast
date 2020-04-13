
resource "google_sql_database" "main" {
  name     = "main"
  instance = google_sql_database_instance.main_primary.name

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "google_sql_database_instance" "main_primary" {
  # Append random chars to avoid errors from trying to reuse the name of a
  # recently deleted instance. After an instance is destroyed, the name can't be
  # reused for up to a week. 4 chars = 1.6 million possible IDs
  # We use random_string because the name can only container lowercase letters,
  # numbers, and hyphens.
  name             = "main-primary-${random_string.four_chars.result}"
  database_version = "POSTGRES_12"
  depends_on       = [var.db_depends_on]

  settings {
    tier              = var.instance_type
    availability_type = "REGIONAL"    # storage distributed across zones for high availability
    disk_size         = var.disk_size # 1.7 TB, min size to get max IOPS from google

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
      ipv4_enabled    = false       # don't give the db a public IPv4
      private_network = var.vpc_uri # link to the VPC where the db will be assigned a private IP
    }

    maintenance_window {
      day  = 6 # saturday
      hour = 9 # 2am PST, 5am EST, 9am UTC
    }
  }
}

resource "google_sql_user" "db_user" {
  name     = var.user
  instance = google_sql_database_instance.main_primary.name
  password = var.password
}

# This is for appending a suffix to the database instance name. This name needs
# to be random, because once destroyed, an instance name can't be reused for up
# to one week.
resource "random_string" "four_chars" {
  length  = 4
  upper   = false # instance names can only have lowercase letters, numbers, and hyphens
  special = false
}
