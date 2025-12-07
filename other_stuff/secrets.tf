# Enable Secrets Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Create a dedicated Google Service Account (SA) which will read secrets from Secret Manager
resource "google_service_account" "secrets_reader" {
  account_id   = "secrets-reader"
  display_name = "This SA will be impersonated by a k8s SA to mount secrets in K8s"
}

# Create my-secret using module
module "my_secret" {
  source = "../modules/secret-with-workload-identity"

  secret_id                    = "my-secret"
  secret_data                  = "My_SECRET_PLACEHOLDER"
  gcp_project                  = var.gcp_project
  gcp_service_account_name     = google_service_account.secrets_reader.name
  gcp_service_account_email    = google_service_account.secrets_reader.email
  k8s_service_accounts         = ["default/mypod"]
  secretmanager_api_dependency = google_project_service.secretmanager
}

# Create slack-webhook secret using module
module "slack_webhook" {
  source = "../modules/secret-with-workload-identity"

  secret_id                    = "slack-webhook"
  secret_data                  = "SLACK_WEBHOOK_PLACEHOLDER"
  gcp_project                  = var.gcp_project
  gcp_service_account_name     = google_service_account.secrets_reader.name
  gcp_service_account_email    = google_service_account.secrets_reader.email
  k8s_service_accounts         = ["monitoring/alertmanager"]
  secretmanager_api_dependency = google_project_service.secretmanager
}


# Outputs
output "service_account_workload_email" {
  description = "Service Account used for reading secrets in Secret Manager"
  value       = google_service_account.secrets_reader.email
}
