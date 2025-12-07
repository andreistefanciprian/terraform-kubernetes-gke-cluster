# Create secret
resource "google_secret_manager_secret" "secret" {
  provider  = google-beta
  secret_id = var.secret_id

  replication {
    auto {}
  }

  depends_on = [var.secretmanager_api_dependency]
}

# Add secret version
resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data
}

# Grant k8s SA permission to impersonate Google SA via workload identity
resource "google_service_account_iam_member" "workload_identity" {
  for_each           = toset(var.k8s_service_accounts)
  service_account_id = var.gcp_service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project}.svc.id.goog[${each.value}]"
}

# Grant Google SA permission to access secret
resource "google_secret_manager_secret_iam_binding" "secret_accessor" {
  project   = google_secret_manager_secret.secret.project
  secret_id = google_secret_manager_secret.secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${var.gcp_service_account_email}",
  ]
}
