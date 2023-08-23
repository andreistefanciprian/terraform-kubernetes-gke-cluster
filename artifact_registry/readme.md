## Description

This Terraform code automates the creation of a dedicated Google Service Account for use with GitHub Actions. The service account is configured to push Helm charts and container images to Google Artifact Registry. Additionally, the code sets up Workload Identity Federation, enabling secure authentication and access for GitHub Actions.

Github Actions workflow used for pushing charts and images [here](https://github.com/andreistefanciprian/go-demo-app/blob/main/.github/workflows/test_and_push_image.yaml#L71-L74).

### Code Overview

The provided Terraform code accomplishes the following tasks:

1. **Create Google Service Account**:
   - This service account is intended for GitHub Actions to interact with Google Artifact Registry.

2. **Create CMEK Keyring and Crypto Key**:
   - Establishes a Customer-Managed Encryption Key (CMEK) keyring and crypto key.
   - Used to provide encryption and decryption capabilities.

3. **Grant Permissions to Encrypt/Decrypt**:
   - Grants the Google Artifact Registry Service Agent SA permission to encrypt and decrypt data using the CMEK key.

4. **Create Dedicated Artifact Registries**:
   - Creates separate Artifact Registries for container images and Helm charts.

5. **Grant Permissions to GitHub Actions SA**:
   - Grants the GitHub Actions Service Account permissions to write to both the image and Helm chart registries.

6. **Configure Workload Identity Federation**:
   - Sets up a Workload Identity Pool and Provider for GitHub Actions.
   - Enables secure authentication and impersonation capabilities.

### How to Use

    ```
    # Build
    make deploy-auto-approve TF_TARGET=artifact_registry

    # Destroy
    make destroy-auto-approve TF_TARGET=artifact_registry
    ```