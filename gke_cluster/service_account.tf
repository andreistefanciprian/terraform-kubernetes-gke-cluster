resource "google_project_service" "iam" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

resource "google_service_account" "cluster" {
  account_id   = var.service_account_name_cluster
  display_name = var.service_account_name_cluster
  project      = var.gcp_project
  depends_on = [google_project_service.iam]
}

locals {
  cluster_service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader"
  ]
}

resource "google_project_iam_member" "cluster" {
  for_each = toset(local.cluster_service_account_roles)
  project  = var.gcp_project
  role     = each.value
  member   = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_service_account_key" "cluster" {
  service_account_id = google_service_account.cluster.email
  key_algorithm      = "KEY_ALG_RSA_2048"
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}