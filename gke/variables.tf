# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
}
# define GCP project name
variable "gcp_project" {
  type        = string
  description = "GCP project name"
}

variable "tfstate_bucket" {
  type        = string
  description = "GCS bucket name for Terraform state"
}

variable "maintenance_window" {
  description = "Time window specified for daily maintenance operations to START in RFC3339 format"
  type        = string
  default     = "05:00"
}

variable "node_type" {
  type    = string
  default = "n1-standard-2"
}

variable "node_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "node_disk_size" {
  type    = number
  default = 10
}

variable "project_name" {
  type        = string
  description = "Name prefix used across all resources for consistent naming"
  default     = "home"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "gke_master_cidr" {
  type        = string
  description = "Private IP subnet for GKE control plane"
  default     = "172.16.0.0/28"
}
