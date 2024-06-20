# Enable Secrets Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Create secret
resource "google_secret_manager_secret" "my-secret" {
  provider = google-beta

  secret_id = "my-secret"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Add secret version
resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret      = google_secret_manager_secret.my-secret.id
  secret_data = "BLABLABLA"
}

# Create a dedicated Google Service Account (SA) which will read secrets from Secret Manager
resource "google_service_account" "secrets_reader" {
  account_id   = "secrets-reader"
  display_name = "This SA will be impersonated by a k8s SA to mount secrets in K8s"
}

# Grant k8s SA permission to impersonate Google SA via workload identity
resource "google_service_account_iam_binding" "service-account-iam" {
  service_account_id = google_service_account.secrets_reader.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[default/mypod]",
  ]
}

# Grant Google SA permission to access secerets in Secret Manager
resource "google_secret_manager_secret_iam_binding" "binding" {
  project   = google_secret_manager_secret.my-secret.project
  secret_id = google_secret_manager_secret.my-secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.secrets_reader.email}",
  ]
}

# Outputs
output "service_account_workload_email" {
  description = "Service Account used for reading secrets in Secret Manager"
  value       = google_service_account.secrets_reader.email
}
