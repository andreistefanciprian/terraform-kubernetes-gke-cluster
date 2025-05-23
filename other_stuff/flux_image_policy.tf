# https://fluxcd.io/flux/guides/cron-job-image-auth/#gcp-container-registry
# Used by go-demo-app flux ImageRepository

# # Enable IAM API
resource "google_project_service" "iam" {
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Service account to generate short lived token for flux ImageRepository authentication to GAR
resource "google_service_account" "flux" {
  account_id   = "flux-gar-authenticator"
  display_name = "To be impersonated by a k8s SA"
}

# Grant k8s SA permission to impersonate Google SA via workload identity
resource "google_service_account_iam_binding" "flux" {
  service_account_id = google_service_account.flux.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    # "serviceAccount:${var.gcp_project}.svc.id.goog[flux-system/gcr-credentials-sync]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[flux-system/kustomize-controller]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[flux-system/source-controller]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[flux-system/image-reflector-controller]",
  ]
}

# Grant SA permission to consume from image registry
resource "google_artifact_registry_repository_iam_member" "flux_image_reader" {
  project    = google_artifact_registry_repository.cmek-container-images.project
  location   = google_artifact_registry_repository.cmek-container-images.location
  repository = google_artifact_registry_repository.cmek-container-images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.flux.email}"
}

# Grant SA permission to consume from helm registry
resource "google_artifact_registry_repository_iam_member" "flux_chart_reader" {
  project    = google_artifact_registry_repository.cmek-helm-charts.project
  location   = google_artifact_registry_repository.cmek-helm-charts.location
  repository = google_artifact_registry_repository.cmek-helm-charts.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.flux.email}"
}

# Grant SA permission to consume from manifests registry (flux OCI Repos)
resource "google_artifact_registry_repository_iam_member" "manifests_reader" {
  project    = google_artifact_registry_repository.manifests.project
  location   = google_artifact_registry_repository.manifests.location
  repository = google_artifact_registry_repository.manifests.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.flux.email}"
}