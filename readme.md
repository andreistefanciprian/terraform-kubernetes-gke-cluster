# Google Kubernetes Engine (GKE) Cluster with Terraform

This repository provisions the core infrastructure for a GKE cluster on Google Cloud Platform (GCP) using Terraform.

> **📦 Complete Stack:** This repository is part of a two-repo setup:
> 1. **This repo** - Provisions infrastructure (VPC, GKE cluster, secrets, certificate authority, artifact registry, etc)
> 2. **[flux-demo](https://github.com/andreistefanciprian/flux-demo)** - Deploys applications and services on the cluster using FluxCD
>
> After deploying infrastructure here, follow the [flux-demo guide](https://github.com/andreistefanciprian/flux-demo) to deploy your Kubernetes ecosystem.

> ⚠️ **Note:** Some firewall rules (SSH, unrestricted internet) and public GKE endpoint are included for development/debugging. Remove these in production environments.

## Prerequisites

Before getting started, ensure you have:

* **[gcloud CLI](https://cloud.google.com/sdk/docs/install)** - For interacting with Google Cloud
* **[GCP Account](https://console.cloud.google.com/)** - Active project with billing enabled
* **[Docker Compose](https://docs.docker.com/compose/install/other/)** - Terraform runs in a container
* **[Make](https://formulae.brew.sh/formula/make)** - Build automation tool

> 💡 **No local Terraform installation needed** - Everything runs in Docker containers.

## Getting Started

### 1. Initial GCP Setup

```bash
# Set your GCP project environment variables
export GCP_PROJECT=<yourGcpProjectNameGoesHere>
export GCP_EMAIL=<yourAccountNameGoesHere>@gmail.com
export GCP_REGION=<yourGcpRegionGoesHere>

# Initialize and authenticate gcloud CLI
gcloud auth login $GCP_EMAIL

# Run setup script
bash setup.sh
```

### 2. Configure Environment

Copy `env.example` to `.env` and update with your GCP project ID and region:

```bash
cp env.example .env
```

> **Note:** The `TF_VAR_tfstate_bucket` value will be updated after creating the Terraform state bucket in the next step.

### 3. Verify Terraform Version

```bash
make verify_version  # Should show Terraform v1.14.1
```

## Deployment Steps

### Step 1: Create Terraform State Bucket

```bash
docker compose run terraform -chdir=tf_bucket init
docker compose run terraform -chdir=tf_bucket apply -auto-approve
```

> ⚠️ **Important:** After bucket creation, update `TF_VAR_tfstate_bucket` in your `.env` file with the bucket name.

### Step 2: Deploy Networking

```bash
make plan TF_TARGET=networking
make deploy-auto-approve TF_TARGET=networking
```

Creates: VPC, subnets, Cloud NAT, and firewall rules.

### Step 3: Deploy GKE Cluster

```bash
make plan TF_TARGET=gke
make deploy-auto-approve TF_TARGET=gke

# Configure kubectl
gcloud container clusters get-credentials ${GCP_PROJECT}-gke --region $GCP_REGION --project $GCP_PROJECT
kubectl cluster-info
```

### Step 4: Deploy Supporting Infrastructure

```bash
make deploy-auto-approve TF_TARGET=other_stuff
```

Creates: Google Secrets Manager, Artifact Registry, Certificate Authority Service.

## Next Steps: Deploy Applications

Once infrastructure is deployed, install Kubernetes applications using FluxCD:

👉 **Follow the [flux-demo repository](https://github.com/andreistefanciprian/flux-demo)** to deploy:
* cert-manager (certificate lifecycle management)
* kube-prometheus-stack (monitoring)
* secrets-store-csi-driver
* Istio service mesh
* Your applications

## Cleanup

### Destroy All Resources

```bash
# Destroy in reverse order
make destroy-auto-approve TF_TARGET=other_stuff
make destroy-auto-approve TF_TARGET=gke
make destroy-auto-approve TF_TARGET=networking

# Destroy state bucket
docker-compose run terraform -chdir=tf_bucket destroy -auto-approve
```

### Clean Local Terraform Files

```bash
make clean TF_TARGET=tf_bucket
make clean TF_TARGET=networking
make clean TF_TARGET=gke
make clean TF_TARGET=other_stuff
```
