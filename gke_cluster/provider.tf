terraform {
  required_version = ">= 1.6.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0" # OIDC https://github.com/hashicorp/terraform-provider-google/releases/tag/v3.61.0
    }
  }

}
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}
