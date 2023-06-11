# get project number
data "google_project" "project" {
  project_id = var.gcp_project
}