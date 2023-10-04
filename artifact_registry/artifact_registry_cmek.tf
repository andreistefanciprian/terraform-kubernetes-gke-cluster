# Enable Google Services API
resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudkms" {
  service = "cloudkms.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

# do we need mesh? might be used by ASM
resource "google_project_service" "mesh" {
  service = "mesh.googleapis.com"
}

resource "google_project_service" "sts" {
  service = "sts.googleapis.com"
}

# Create a dedicated Google Service Account which will push the Helm charts and Container Images to Artifact Registry
resource "google_service_account" "ghr" {
  account_id   = "github-runner"
  display_name = "Github Actions Service Account used to push artefacts in GAR"
}

# Create CMEK keyring and crypto key
resource "google_kms_key_ring" "test" {
  name     = var.app_name
  location = var.gcp_region
}

resource "google_kms_crypto_key" "test" {
  name            = var.app_name
  key_ring        = google_kms_key_ring.test.id
  rotation_period = "100000s"
  purpose         = "ENCRYPT_DECRYPT"
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Grant GAR Service Agent SA permission to encrypt/decrypt with the CMEK key
resource "google_project_service_identity" "gar_sa" {
  provider = google-beta
  project  = var.gcp_project
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.test.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.gar_sa.email}"
  depends_on = [
    google_project_service_identity.gar_sa
  ]
}

#  Create dedicated Artifactory registry for container images
resource "google_artifact_registry_repository" "cmek-container-images" {
  location      = var.gcp_region
  repository_id = "cmek-container-images"
  description   = "CMEK Container Image Registry"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.test.id
  depends_on = [
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

#  Create dedicated Artifactory registry for helm charts
resource "google_artifact_registry_repository" "cmek-helm-charts" {
  location      = var.gcp_region
  repository_id = "cmek-helm-charts"
  description   = "CMEK Helm Chart Registry"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.test.id
  depends_on = [
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

# Grant GHA SA permission to write to image registry
resource "google_artifact_registry_repository_iam_member" "cmek_image_registry_writer" {
  project    = google_artifact_registry_repository.cmek-container-images.project
  location   = google_artifact_registry_repository.cmek-container-images.location
  repository = google_artifact_registry_repository.cmek-container-images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ghr.email}"
}

# Grant GHA SA permission to write to helm registry
resource "google_artifact_registry_repository_iam_member" "cmek_helm_registry_writer" {
  project    = google_artifact_registry_repository.cmek-helm-charts.project
  location   = google_artifact_registry_repository.cmek-helm-charts.location
  repository = google_artifact_registry_repository.cmek-helm-charts.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ghr.email}"
}

# Workload Identity Federation configuration
# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "go-demo-app" {
  workload_identity_pool_id = var.app_name
  description               = "Identity pool for Github Actions"
}

# Create a Workload Identity Provider with GitHub actions
resource "google_iam_workload_identity_pool_provider" "go-demo-app" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.go-demo-app.workload_identity_pool_id
  workload_identity_pool_provider_id = var.app_name
  attribute_mapping = {
    "google.subject"       = "assertion.sub",
    "attribute.actor"      = "assertion.actor",
    "attribute.aud"        = "assertion.aud",
    "attribute.repository" = "assertion.repository",
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow authentications from the Workload Identity Provider to impersonate the gha Service Account
resource "google_service_account_iam_member" "gha_impersonator" {
  service_account_id = google_service_account.ghr.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.go-demo-app.name}/attribute.repository/andreistefanciprian/${var.app_name}"
}

# Outputs
output "google_iam_workload_identity_pool_provider_github_name" {
  description = "Workload Identity Pool Provider ID"
  value       = google_iam_workload_identity_pool_provider.go-demo-app.name
}

output "google_iam_workload_identity_pool_name" {
  description = "Workload Identity Pool Name"
  value       = google_iam_workload_identity_pool.go-demo-app.name
}

output "service_account_github_actions_email" {
  description = "Service Account used by GitHub Actions"
  value       = google_service_account.ghr.email
}
