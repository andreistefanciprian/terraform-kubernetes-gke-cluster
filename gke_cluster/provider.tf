terraform {
  required_version = ">= 1.2.5"
}
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}
