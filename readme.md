# Google Kubernetes Engine (GKE) Cluster with Terraform

This repository contains Terraform code that automates the provisioning of a GKE cluster and associated resources in Google Cloud Platform (GCP).

The primary components include:
* Private GKE Cluster with Public Endpoint and Workload Identity enabled.
* Google Artifact Registry (GAR): 
    * A Docker and Helm chart registry that integrates with [Github Actions Pipeline](https://github.com/andreistefanciprian/go-demo-app) for a demo app.
    * Authentication to GAR from the Github Actions Runner is done via [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
* [Certificate Authority Service](https://cloud.google.com/certificate-authority-service/docs) (used by cert-manager to manage certifictes)
* Firewall Rules: Network rules that enable specific traffic patterns, including internet access from private nodes, Istio auto-injection, and SSH connectivity for debugging.
* [GKE Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) enabled and used by a Kubernetes [workload](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp/tree/main/examples) to impersonate an IAM Service Account and access secrets in Google Secrets Manager

Note: The firewall rules to enable internet access from private nodes and SSH connectivity are primarily for testing and debugging. Avoid enabling these rules in a production environment.

## Prerequisites

Before using the scripts in this repository, make sure you have the following tools installed:

* [gcloud CLI](https://cloud.google.com/sdk/docs/install): Used to interact with Google Cloud resources.
* [Google Cloud Console Account](https://console.cloud.google.com/): Access to a GCP account and project where the resources will be provisioned.
* [Docker Compose](https://docs.docker.com/compose/install/other/): Terraform will run in a container.
* [Make](https://formulae.brew.sh/formula/make): A build automation tool used to manage the terraform workflow.

Since Terraform runs inside a Docker container, you don't need to install it on your machine.

## Initial GCP Setup for Terraform

    # Set your GCP project env vars
    export GCP_PROJECT=<yourGcpProjectNameGoesHere>
    export GCP_EMAIL=<yourAccountNameGoesHere>@gmail.com
    export GCP_REGION=<yourGcpRegionGoesHere>

    # Initialize and authenticate gcloud CLI
    # (follow the prompt to authenticate in your browser)
    gcloud auth login $GCP_EMAIL

    # Run script
    bash setup.sh

## Configuration

Copy `env.example` to `.env` and update with your GCP project ID and region. The `TF_VAR_tfstate_bucket` value will be set after creating the Terraform state bucket.

```bash
cp env.example .env
```

## Using Terraform

This repository uses Terraform version 1.14.1:

    make verify_version

    # clean tf related files (local state, lock, cache) from previous runs
    make clean TF_TARGET=tf_bucket
    make clean TF_TARGET=networking
    make clean TF_TARGET=gke
    make clean TF_TARGET=other_stuff

#### Build GCP resources

1. Create GCP bucket for storing terraform state files
    ```
    # create terraform bucket for storing tf state
    docker compose run terraform -chdir=tf_bucket init
    docker compose run terraform -chdir=tf_bucket apply -auto-approve
    ```
Note: Once you have created your Terraform state bucket, update the bucket name variable (TF_VAR_tfstate_bucket) in the .env file.

2. Create networking infrastructure
    ```
    # create VPC, subnets, NAT gateway
    make plan TF_TARGET=networking
    make deploy-auto-approve TF_TARGET=networking
    ```

3. Create GKE cluster
    ```
    # create K8s cluster (GKE)
    make plan TF_TARGET=gke
    make deploy-auto-approve TF_TARGET=gke

    # configure kubectl profile
    gcloud container clusters get-credentials ${GCP_PROJECT}-gke --region $GCP_REGION --project $GCP_PROJECT
    kubectl cluster-info
    ```
    
4. Create other infrastructure
    ```
    # create secret in Google Secrets and allow GKE workload SA default/mypod to impersonate IAM SA and access the secret
    # create Google Artifact Registry (GAR) and configure external auth via Workload Identity Federation
    make deploy-auto-approve TF_TARGET=other_stuff
    ```

#### Destroy terraform resources
    ```
    # destroy terraform resources
    make destroy-auto-approve TF_TARGET=other_stuff
    make destroy-auto-approve TF_TARGET=gke
    make destroy-auto-approve TF_TARGET=networking
    
    # destroy terraform state bucket
    docker-compose run terraform -chdir=tf_bucket destroy -auto-approve

    # clean tf related files (local state, lock, cache)
    make clean TF_TARGET=tf_bucket
    make clean TF_TARGET=networking
    make clean TF_TARGET=gke
    make clean TF_TARGET=other_stuff
    ```

## OPTIONAL: Build k8s ecosystem with fluxcd

Installs:
* cert-manager (automatically manage certificates lifecycle)
* kube-prometheus-stack (monitoring)
* secrets-store-csi-driver
* istio service mesh
* other apps

Follow steps [here](https://github.com/andreistefanciprian/flux-demo).
