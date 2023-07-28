# Google Kubernetes Engine (GKE) Cluster with Terraform

This repository contains Terraform code that automate the provisioning of a GKE cluster and associated resources on Google Cloud Platform (GCP).

The primary components include:
* Private GKE Cluster with Public Endpoint: A Kubernetes cluster that's private with a publically accessible endpoint.
* Artifact Registry: A Docker and Helm chart registry that integrates with [Github Actions Pipeline](https://github.com/andreistefanciprian/go-demo-app) for a demo app.
* Firewall Rules: Network rules that enable specific traffic patterns, including internet access from private nodes, Istio auto-injection, and SSH connectivity for debugging.

Note: The firewall rules to enable internet access from private nodes and SSH connectivity are primarily for testing and debugging. Avoid enabling these rules in a production environment.

## Prerequisites

Before using the scripts in this repository, make sure you have the following tools installed:

* [gcloud CLI](https://cloud.google.com/sdk/docs/install): Used to interact with Google Cloud resources.
* [Google Cloud Console Account](https://console.cloud.google.com/): Access to a GCP account and project where the resources will be provisioned.
* [Docker Compose](https://docs.docker.com/compose/install/other/): Terraform will run in a container.
* [Make](https://formulae.brew.sh/formula/make): A build automation tool used to manage the terraform workflow.

Since Terraform runs inside a Docker container, you don't need to install it on your machine.

## Initial GCP Setup for Terraform

    ```
    # Set your GCP project details
    GCP_PROJECT=<yourGcpProjectNameGoesHere>
    GCP_EMAIL=<yourAccountNameGoesHere>@gmail.com
    GCP_REGION=<yourGcpRegionGoesHere>

    # Initialize and authenticate gcloud CLI
    # (follow the prompt to authenticate in your browser)
    gcloud auth login $GCP_EMAIL

    # Set gcloud to use your project and region
    gcloud config set project $GCP_PROJECT
    gcloud config set account $GCP_EMAIL

    # Enable necessary GCP APIs
    gcloud services enable --project $GCP_PROJECT \
    artifactregistry.googleapis.com \
    cloudresourcemanager.googleapis.com \
    servicenetworking.googleapis.com \
    servicemanagement.googleapis.com \
    iamcredentials.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com \
    sts.googleapis.com \
    cloudkms.googleapis.com \
    mesh.googleapis.com

    gcloud config set compute/region $GCP_REGION
    gcloud config set compute/zone ${GCP_REGION}-a

    # check gcloud config
    gcloud config list

    # Create and set up Terraform service account
    gcloud iam service-accounts create terraform \
    --description="Used by Terraform" \
    --display-name="Terraform"

    # Verify service account was created
    gcloud iam service-accounts list

    # Grant the necessary roles to the service account
    gcloud projects add-iam-policy-binding $GCP_PROJECT \
    --member="serviceAccount:terraform@${GCP_PROJECT}.iam.gserviceaccount.com" \
    --role="roles/container.admin" \
    --role="roles/storage.admin" \
    --role="roles/compute.admin" \
    --role="roles/storage.legacyBucketWriter" \
    --role="roles/owner"

    # Describe service account
    gcloud iam service-accounts describe terraform@${GCP_PROJECT}.iam.gserviceaccount.com

    # Generate and download a service account key
    gcloud iam service-accounts keys create gcp_sa_key.json \
    --iam-account=terraform@${GCP_PROJECT}.iam.gserviceaccount.com
    ```

## Using Terraform

This repository uses Terraform version 1.2.5:
    ```
    make verify_version
    ```

Before using terraform to build resources in a new GCP project, make sure you clean pre-existing state, lock and cache files from previous GCP projects:
    ```
    make verify_version
    make clean TF_TARGET=tf_bucket
    make clean TF_TARGET=gke_cluster
    ```

Also update the .env file in your directory with your GCP project details and the location of your service account key. 

#### Create GCP bucket for storing terraform state files

Note: use docker-compose for creating the tf_state bucket
    ```
    # create terraform resource
    docker-compose run terraform -chdir=tf_bucket init
    docker-compose run terraform -chdir=tf_bucket apply -auto-approve
    ```

Note: Once you have created your Terraform state bucket, update the bucket name variable (TFSTATE_BUCKET) in the Makefile.

#### Create terraform resources (GKE cluster and GAR)

    ```
    # create K8s cluster (GKE)
    make plan TF_TARGET=gke_cluster
    make deploy-auto-approve TF_TARGET=gke_cluster

    # configure kubectl profile
    gcloud container clusters get-credentials ${GCP_PROJECT}-gke --region $GCP_REGION --project $GCP_PROJECT

    # create artifact registry (GAR)
    make deploy-auto-approve TF_TARGET=artifact_registry
    ```

#### Destroy terraform resources

    ```
    # destroy terraform resources (GKE and GAR)
    make destroy-auto-approve TF_TARGET=gke_cluster
    make destroy-auto-approve TF_TARGET=artifact_registry

    # destroy terraform state bucket
    docker-compose run terraform -chdir=tf_bucket destroy -auto-approve
    ```

#### Debug

    ```
    # ssh into gke nodes
    gcloud compute instances list
    gcloud compute ssh <instanceName> --zone ${GCP_REGION}-a --tunnel-through-iap

    # test internet connectivity from GKE node
    gcloud compute routers create nat-router \
        --network ${GCP_PROJECT}-vpc \
        --region $GCP_REGION

    sudo nsenter --target `pgrep '^kube-dns$'` --net /bin/bash
    curl -I example.com
    ```