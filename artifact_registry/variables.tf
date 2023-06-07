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

variable "github_repo_owner" {
  type    = string
  default = "andreistefanciprian"
}

variable "app_name" {
  type    = string
  default = "go-demo-app"
}