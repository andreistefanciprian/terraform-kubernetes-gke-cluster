# GKE cluster
resource "google_project_service" "container" {
  service                    = "container.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_container_cluster" "primary" {
  provider           = google-beta
  name               = var.project_name
  location           = var.gcp_region
  network            = data.terraform_remote_state.networking.outputs.vpc_name
  subnetwork         = data.terraform_remote_state.networking.outputs.subnet_name
  logging_service    = "logging.googleapis.com/kubernetes"    # Lets use Stackdriver
  monitoring_service = "monitoring.googleapis.com/kubernetes" # Lets use Stackdriver

  enable_shielded_nodes       = true         # https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes
  enable_intranode_visibility = true         # https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility
  networking_mode             = "VPC_NATIVE" # Required for private service networking to services

  deletion_protection = false

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.gke_master_cidr
  }

  # https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "" # Let GCP choose
    services_ipv4_cidr_block = "" # Let GCP choose
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = true # We'd like certificate, not basic authentication
    }
  }

  # recommended way to safely access Google Cloud services from GKE applications.
  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog" # https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_window
    }
  }

  vertical_pod_autoscaling {
    enabled = true
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  initial_node_count = 1

  addons_config {
    istio_config {
      disabled = "true"
      # auth = "AUTH_MUTUAL_TLS"
    }

    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  resource_labels = {
    env     = var.project_name
    mesh_id = "proj-${data.google_project.project.number}"
  }

  timeouts {
    create = "30m"
    update = "40m"
  }

  depends_on = [google_service_account.cluster]
}

# Separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name     = var.project_name
  location = var.gcp_region
  cluster  = google_container_cluster.primary.name

  node_count = var.gke_num_nodes

  node_config {
    machine_type = var.node_type
    preemptible  = true
    disk_size_gb = var.node_disk_size
    disk_type    = var.node_disk_type

    service_account = google_service_account.cluster.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project_name
    }

    tags = ["gke-node", var.project_name]
  }
}