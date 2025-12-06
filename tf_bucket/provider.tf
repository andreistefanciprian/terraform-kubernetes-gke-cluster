terraform {
  required_version = ">= 1.14.1"
}
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}