#  Create dedicated Artifactory registry for container images
resource "google_artifact_registry_repository" "docker-repo" {
  location      = var.gcp_region
  repository_id = "container-images"
  description   = "Docker image repository"
  format        = "DOCKER"
}

# Grant GHA SA permission to write to registry
resource "google_artifact_registry_repository_iam_member" "image_registry_writer" {
  project    = google_artifact_registry_repository.docker-repo.project
  location   = google_artifact_registry_repository.docker-repo.location
  repository = google_artifact_registry_repository.docker-repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.gha_helm.email}"
}

# Create Container Registry
resource "google_container_registry" "my-images" {
  project  = var.gcp_project
  location = "ASIA"
}

# Grant GHA SA permission to write to registry
resource "google_storage_bucket_iam_member" "writer" {
  bucket = google_container_registry.my-images.id
  role   = "roles/storage.legacyBucketWriter"
  member = "serviceAccount:${google_service_account.gha_helm.email}"
}

#  Create dedicated Artifactory registry for helm images
resource "google_artifact_registry_repository" "helm-charts" {
  location      = var.gcp_region
  repository_id = "helm-charts"
  description   = "Helm Charts Registry"
  format        = "DOCKER"
}

# Create a dedicated Google Service Account which will push the Helm chart in Artifact Registry
resource "google_service_account" "gha_helm" {
  account_id   = "gha-helm-push"
  display_name = "Github Actions Service Account used to push the Helm chart in Artifact Registry"
}

# Create a Workload Identity Pool
resource "google_iam_workload_identity_pool" "go-demo-app" {
  workload_identity_pool_id = "go-demo-app"
  description               = "Identity pool for Github Actions"
}

# Create a Workload Identity Provider with GitHub actions
resource "google_iam_workload_identity_pool_provider" "go-demo-app" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.go-demo-app.workload_identity_pool_id
  workload_identity_pool_provider_id = "go-demo-app-prvdr"
  attribute_mapping = {
    "google.subject" = "assertion.sub",
    # "google.subject"       = "assertion.repository",
    "attribute.actor"      = "assertion.actor",
    "attribute.aud"        = "assertion.aud",
    "attribute.repository" = "assertion.repository",
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow authentications from the Workload Identity Provider to impersonate the gha helm Service Account
resource "google_service_account_iam_member" "go-demo-app" {
  service_account_id = google_service_account.gha_helm.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.go-demo-app.name}/attribute.repository/andreistefanciprian/go-demo-app"
}

resource "google_artifact_registry_repository_iam_member" "artifact_registry_writer" {
  project    = google_artifact_registry_repository.helm-charts.project
  location   = google_artifact_registry_repository.helm-charts.location
  repository = google_artifact_registry_repository.helm-charts.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.gha_helm.email}"
}

output "service_account_github_actions_email" {
  description = "Service Account used by GitHub Actions"
  value       = google_service_account.gha_helm.email
}

output "google_iam_workload_identity_pool_provider_github_name" {
  description = "Workload Identity Pool Provider ID"
  value       = google_iam_workload_identity_pool_provider.go-demo-app.name
}

output "google_iam_workload_identity_pool_name" {
  description = "Workload Identity Pool Name"
  value       = google_iam_workload_identity_pool.go-demo-app.name
}