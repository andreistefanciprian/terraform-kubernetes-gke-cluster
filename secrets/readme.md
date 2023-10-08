## Description

This Terraform code facilitates secret and certificate management in Google Cloud Platform (GCP) via Google Secret Manager and Google Certificate Authority Service (CAS). It enables smooth integration with Kubernetes workloads, utilizing [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity).

### secrets.tf Code Overview

The provided Terraform code accomplishes the following tasks:
1. **Enables Secrets Manager API**
2. **Creates Secret**
3. **Creates Google Service Account (SA)**
    - This service account is designed for accessing secrets stored in Secret Manager.
    - The service account can also be impersonated by a Kubernetes Service Account of a specific workload.

Here is an [example](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/tree/main/examples) of a GKE workload that can impersonate the Google SA and mount the secret inside the pod.

### cas.tf Code Overview

Builds the CAS infrastructure for [cert-manager GoogleCASClusterIssuer](https://github.com/andreistefanciprian/flux-demo/tree/main/infra/cert-manager):
Cert-manager GoogleCASClusterIssuer requests and manages certificates for kubernetes workloads.

Here is an [example](https://github.com/andreistefanciprian/flux-demo/blob/main/clusters/home/demo-cert.yaml) of a certificate issued in K8s by the GoogleCASClusterIssuer.

### How to Use

    ```
    # Build
    make deploy-auto-approve TF_TARGET=secrets

    # Destroy
    make destroy-auto-approve TF_TARGET=secrets
    ```