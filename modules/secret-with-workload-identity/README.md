# Secret with Workload Identity Module

This module creates a Google Secret Manager secret and configures Workload Identity to allow Kubernetes service accounts to read it via a GCP service account.

## Usage

```hcl
module "my_secret" {
  source = "../modules/secret-with-workload-identity"

  secret_id                    = "my-secret"
  secret_data                  = "BLABLABLA"
  gcp_project                  = var.gcp_project
  gcp_service_account_name     = google_service_account.secrets_reader.name
  gcp_service_account_email    = google_service_account.secrets_reader.email
  k8s_service_accounts         = ["default/mypod"]
  secretmanager_api_dependency = google_project_service.secretmanager
}
```

## Features

- Creates a Secret Manager secret with automatic replication
- Grants multiple Kubernetes service accounts permission to impersonate a GCP service account
- Grants the GCP service account permission to read the secret

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| secret_id | The ID of the secret to create | string | yes |
| secret_data | The secret data/value | string | yes |
| gcp_project | GCP project ID | string | yes |
| gcp_service_account_name | The name of the GCP service account | string | yes |
| gcp_service_account_email | The email of the GCP service account | string | yes |
| k8s_service_accounts | List of K8s SAs (namespace/name format) | list(string) | yes |
| secretmanager_api_dependency | Dependency on Secret Manager API | any | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_id | The ID of the created secret |
| secret_name | The full name of the created secret |
| secret_version_id | The version ID of the secret |
