
# generate unique number to be used for gcp resource unique names
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

locals {
  gcs_tfstate_bucket_name = "${var.gcp_bucket_prefix}-${random_integer.rand.result}"
}

# Create a GCS Bucket
resource "google_storage_bucket" "tf-bucket" {
  project       = var.gcp_project
  name          = local.gcs_tfstate_bucket_name
  location      = var.gcp_region
  force_destroy = true
  storage_class = var.storage-class
  versioning {
    enabled = true
  }
}