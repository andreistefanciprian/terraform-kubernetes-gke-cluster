# Description

* Build K8s cluster and Artifact Registry in Google Cloud with Terraform.
* Golang demo app with github actions workflows for pushing helm chart and container image to Artifact Registry [here](https://github.com/andreistefanciprian/go-demo-app).

## Requirements

* gcloud CLI (https://cloud.google.com/sdk/docs/install)
* Gogle Cloud Console account and project (https://console.cloud.google.com/)
* docker-compose (https://docs.docker.com/compose/install/other/)
* make (https://formulae.brew.sh/formula/make)

We will run terraform from a docker container, so no need to install it.

## Set up the necessary infrastructure on GCP for use with Terraform

```
# define vars
GCP_PROJECT=<yourGcpProjectNameGoesHere>
GCP_EMAIL=<yourAccountNameGoesHere>@gmail.com
GCP_REGION=<yourGcpRegionGoesHere>

# setup gcp demo account 
gcloud config set project $GCP_PROJECT
gcloud config set account $GCP_EMAIL
gcloud config set compute/region $GCP_REGION
gcloud config set compute/zone ${GCP_REGION}-a

# enable GCP APIs
gcloud services enable --project $GCP_PROJECT \
artifactregistry.googleapis.com \
cloudresourcemanager.googleapis.com \
servicenetworking.googleapis.com \
servicemanagement.googleapis.com \
iamcredentials.googleapis.com \
compute.googleapis.com \
container.googleapis.com \
sts.googleapis.com \
cloudkms.googleapis.com

# create terraform service account
gcloud iam service-accounts create terraform \
--description="Used by Terraform" \
--display-name="Terraform"

# verify service account was created
gcloud iam service-accounts list

# bind project owner role to terraform sa
gcloud projects add-iam-policy-binding $GCP_PROJECT \
--member="serviceAccount:terraform@${GCP_PROJECT}.iam.gserviceaccount.com" \
--role="roles/container.admin" \
--role="roles/storage.admin" \
--role="roles/compute.admin" \
--role="roles/storage.legacyBucketWriter" \
--role="roles/owner"

# describe service account
gcloud iam service-accounts describe terraform@${GCP_PROJECT}.iam.gserviceaccount.com

# create Terraform SA key
gcloud iam service-accounts keys create gcp_sa_key.json \
--iam-account=terraform@${GCP_PROJECT}.iam.gserviceaccount.com
```

## Terraform

This repo use terraform version 1.2.5

#### How to use terraform to create/destroy resources

Note: 
* terraform SA Key (gcp_sa_key.json) should be available in current directory
* Before running terraform update .env file in current directory:
    * update TF_VAR_gcp_project and TF_VAR_gcp_region to match your GCP details
    * define terraform credentials GOOGLE_APPLICATION_CREDENTIALS="/var/tmp/code/gcp_sa_key.json"
* After creating tf bucket, update bucket name var (TFSTATE_BUCKET=...) in the makefile

#### Create GCP bucket for storing terraform state files

Note: use docker-compose for creating the tf_state bucket
```
# create terraform resource
docker-compose run terraform -chdir=tf_bucket apply -auto-approve
```

#### Create terraform resources

```
# create terraform resources
make verify_version
make plan TF_TARGET=gke_cluster
make deploy-auto-approve TF_TARGET=gke_cluster

# configure kubectl profile
gcloud container clusters get-credentials ${GCP_PROJECT}-gke --region $GCP_REGION --project $GCP_PROJECT
```

#### Destroy terraform resources

```
# destroy terraform resources
docker-compose run terraform -chdir=tf_bucket destroy -auto-approve

# destroy terraform resources
make destroy-auto-approve TF_TARGET=gke_cluster
```