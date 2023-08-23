## Description

This Terraform code facilitates secret management and secure access controls in Google Cloud Platform (GCP) via Google Secret Manager. It enables smooth integration with Kubernetes workloads, utilizing [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

### Code Overview

The provided Terraform code accomplishes the following tasks:
1. **Enables Secrets Manager API**
2. **Creates Secret**
3. **Creates Google Service Account (SA)**
4. **Grants Goole SA Secret Access Permissions**
4. **Grants a Kubernetes SA Access to impersonate Google SA**

### How to Use

```
# Build
make deploy-auto-approve TF_TARGET=secrets

# Destroy
make destroy-auto-approve TF_TARGET=secrets
```