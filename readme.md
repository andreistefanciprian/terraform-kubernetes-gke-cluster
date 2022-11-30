# Description

Build a K8s cluster in Google Cloud with Terraform.

## Setup gcloud configuration

```
# define vars
GCP_PROJECT=<yourGcpProjectNameGoesHere>
GCP_EMAIL=<yourAccountNameGoesHere>@gmail.com

# enable GCP Api
gcloud services enable --project $GCP_PROJECT \
cloudresourcemanager.googleapis.com \
servicenetworking.googleapis.com \
servicemanagement.googleapis.com \
iamcredentials.googleapis.com \
compute.googleapis.com \
container.googleapis.com

# setup gcp demo account 
gcloud config set project $GCP_PROJECT
gcloud config set account $GCP_EMAIL
gcloud config set compute/region australia-southeast2
gcloud config set compute/zone australia-southeast2-a

# create terraform service account
gcloud iam service-accounts create terraform \
--description="Used by Terraform" \
--display-name="Terraform"

gcloud iam service-accounts list

# bind project owner role to terraform sa
gcloud projects add-iam-policy-binding $GCP_PROJECT \
--member="serviceAccount:terraform@${GCP_PROJECT}.iam.gserviceaccount.com" \
--role="roles/container.admin" \
--role="roles/storage.admin" \
--role="roles/compute.admin" \
--role="roles/storage.legacyBucketWriter" \
--role="roles/owner"

gcloud iam service-accounts describe terraform@${GCP_PROJECT}.iam.gserviceaccount.com

# create Terraform SA key
gcloud iam service-accounts keys create gcp_sa_key.json \
--iam-account=terraform@${GCP_PROJECT}.iam.gserviceaccount.com
```

# Terraform

This repo use terraform version 1.2.5
Note: gcp_sa_key.json should be available in current dir

## How to use terraform to create/destroy resources

Note: 
* Before running terraform, provide GCP proj name in tf_bucket/terraform.tfvars and gke_cluster/terraform.tfvars files
* After creating tf bucket, provide the created bucket name (TFSTATE_BUCKET=...) in the makefile

```
## Create terraform resources using makefile
make verify_version
make plan TF_TARGET=$TF_FOLDER
make deploy-auto-approve TF_TARGET=$TF_FOLDER
make destroy-auto-approve TF_TARGET=$TF_FOLDER

## Create terraform resources using docker-compose
TF_FOLDER=<folder-name>
docker-compose run terraform version
docker-compose run terraform -chdir=$TF_FOLDER init
docker-compose run terraform -chdir=$TF_FOLDER plan
docker-compose run terraform -chdir=$TF_FOLDER apply -auto-approve
docker-compose run terraform -chdir=$TF_FOLDER destroy -auto-approve
```

## Create GCP bucket for storing terraform state files
```
# create terraform resources
make deploy-auto-approve TF_TARGET=tf_bucket

# destroy terraform resources
make destroy-auto-approve TF_TARGET=tf_bucket
```

## Create GKE cluster
```
# create terraform resources
make verify_version
make plan TF_TARGET=gke_cluster
make deploy-auto-approve TF_TARGET=gke_cluster

# destroy terraform resources
make destroy-auto-approve TF_TARGET=gke_cluster

# get GKE cluster name from GCP Console
# configure kubectl profile
gcloud container clusters get-credentials <gkeClusterNameGoesHere> --region australia-southeast2 --project $GCP_PROJECT
```