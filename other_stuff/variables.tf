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

variable "domain_name" {
  type        = string
  description = "Primary domain name for certificates"
  default     = "netl1.com"
}

variable "domain_organization" {
  type        = string
  description = "Organization name for certificate authority"
  default     = "netl1"
}