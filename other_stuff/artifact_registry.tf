# Enable Google Services API
resource "google_project_service" "artifactregistry" {
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloudkms" {
  service                    = "cloudkms.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

# do we need mesh? might be used by ASM
resource "google_project_service" "mesh" {
  service                    = "mesh.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "sts" {
  service                    = "sts.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create a dedicated Google Service Account which will push the Helm charts and Container Images to Artifact Registry
resource "google_service_account" "ghr" {
  account_id   = "github-runner"
  display_name = "Github Actions Service Account used to push artefacts in GAR"
}

# Create CMEK keyring and crypto key
resource "google_kms_key_ring" "gha" {
  name       = "gha"
  location   = var.gcp_region
  depends_on = [google_project_service.cloudkms]

  lifecycle {
    # KMS KeyRings cannot be deleted in GCP, only scheduled for deletion after 24h
    # To avoid errors on destroy, we'll ignore this resource
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "gha" {
  name            = "gha"
  key_ring        = google_kms_key_ring.gha.id
  rotation_period = "100000s"
  purpose         = "ENCRYPT_DECRYPT"
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }
  lifecycle {
    prevent_destroy = false
  }
}

# Grant GAR Service Agent SA permission to encrypt/decrypt with the CMEK key
resource "google_project_service_identity" "gar_sa" {
  provider = google-beta
  project  = var.gcp_project
  service  = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.gha.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.gar_sa.email}"
  depends_on = [
    google_project_service_identity.gar_sa
  ]
}

#  Create dedicated Artifactory registry for container images
resource "google_artifact_registry_repository" "cmek-container-images" {
  provider      = google-beta
  location      = var.gcp_region
  repository_id = "cmek-container-images"
  description   = "Repository for container images with CMEK encryption"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.gha.id
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
  kms_key_name  = google_kms_crypto_key.gha.id
  depends_on = [
    google_kms_crypto_key_iam_member.crypto_key
  ]
}

#  Create dedicated Artifactory registry for k8s manifests (flux OCI Repos)
resource "google_artifact_registry_repository" "manifests" {
  location      = var.gcp_region
  repository_id = "manifests"
  description   = "OCI Repo Flux Registry for k8s manifests"
  format        = "DOCKER"
  kms_key_name  = google_kms_crypto_key.gha.id
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

# Grant GHA SA permission to write to manifests registry (flux OCI Repos)
resource "google_artifact_registry_repository_iam_member" "manifests_registry_writer" {
  project    = google_artifact_registry_repository.manifests.project
  location   = google_artifact_registry_repository.manifests.location
  repository = google_artifact_registry_repository.manifests.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ghr.email}"
}

# Workload Identity Federation configuration
# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "gha" {
  workload_identity_pool_id = "githubactions-pool"
  description               = "Identity pool for Github Actions"

  lifecycle {
    # Workload Identity Pools are soft-deleted and kept for 30 days
    # Set a unique name or use replace_triggered_by if recreating frequently
    ignore_changes = []
  }
}

# Create a Workload Identity Provider with GitHub actions
resource "google_iam_workload_identity_pool_provider" "default" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gha.workload_identity_pool_id
  workload_identity_pool_provider_id = "githubactions-pool"
  attribute_mapping = {
    "google.subject"             = "assertion.sub",
    "attribute.actor"            = "assertion.actor",
    "attribute.aud"              = "assertion.aud",
    "attribute.repository"       = "assertion.repository",
    "attribute.repository_owner" = "assertion.repository_owner",
  }
  attribute_condition = "assertion.repository_owner == 'andreistefanciprian'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow authentications from the Workload Identity Provider to impersonate the gha Service Account
resource "google_service_account_iam_member" "gha_impersonator" {
  service_account_id = google_service_account.ghr.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gha.name}/attribute.repository/andreistefanciprian/go-demo-app"
}

# not sure I'm using this ????
resource "google_service_account_iam_member" "gha_impersonator_slack_bot" {
  service_account_id = google_service_account.ghr.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gha.name}/attribute.repository/andreistefanciprian/demo_slack_bot"
}

# Outputs
output "google_iam_workload_identity_pool_provider_github_name" {
  description = "Workload Identity Pool Provider ID"
  value       = google_iam_workload_identity_pool_provider.default.name
}

output "google_iam_workload_identity_pool_name" {
  description = "Workload Identity Pool Name"
  value       = google_iam_workload_identity_pool.gha.name
}

output "service_account_github_actions_email" {
  description = "Service Account used by GitHub Actions"
  value       = google_service_account.ghr.email
}
