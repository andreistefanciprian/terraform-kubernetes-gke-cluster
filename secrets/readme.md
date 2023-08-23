## Description

This Terraform code facilitates secret management and secure access controls in Google Cloud Platform (GCP) via Google Secret Manager. It enables smooth integration with Kubernetes workloads, utilizing [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

### Code Overview

The provided Terraform code accomplishes the following tasks:
1. **Enables Secrets Manager API**
2. **Creates Secret**
3. **Creates Google Service Account (SA)**
    - This service account is designed for accessing secrets stored in Secret Manager.
    - The service account can also be impersonated by a Kubernetes Service Account of a specific workload.

### How to Use

    ```
    # Build
    make deploy-auto-approve TF_TARGET=secrets

    # Destroy
    make destroy-auto-approve TF_TARGET=secrets
    ```