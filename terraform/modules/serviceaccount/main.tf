
resource "google_project_service" "enable_iam_api" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "account" {
  account_id  = var.name
  description = "The service account used by Cloud SQL Proxy to connect to the db"
}

resource "google_project_iam_member" "role" {
  role   = var.role
  member = "serviceAccount:${google_service_account.account.email}"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.account.name
}
