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

variable "maintenance_window" {
  description = "Time window specified for daily maintenance operations to START in RFC3339 format"
  type        = string
  default     = "05:00"
}

variable "node_type" {
  type    = string
  default = "n1-standard-1"
}

variable "node_disk_type" {
  type    = string
  default = "pd-standard"
}

variable "node_disk_size" {
  type    = number
  default = 10
}

variable "service_account_name_cluster" {
  type    = string
  default = "demo-cluster"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}
