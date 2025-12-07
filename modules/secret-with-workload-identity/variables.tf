variable "secret_id" {
  description = "The ID of the secret to create"
  type        = string
}

variable "secret_data" {
  description = "The secret data/value"
  type        = string
  sensitive   = true
  default= "SECRET_PLACEHOLDER"
}

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_service_account_name" {
  description = "The name (not email) of the GCP service account that will read the secret"
  type        = string
}

variable "gcp_service_account_email" {
  description = "The email of the GCP service account that will read the secret"
  type        = string
}

variable "k8s_service_accounts" {
  description = "List of Kubernetes service accounts (namespace/name format) that will impersonate the GCP SA"
  type        = list(string)
}

variable "secretmanager_api_dependency" {
  description = "Dependency on the Secret Manager API being enabled"
  type        = any
  default     = null
}
