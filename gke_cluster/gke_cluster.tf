# GKE cluster
# resource "google_service_account" "default" {
#   account_id   = var.service_account_name_cluster
#   display_name = var.service_account_name_cluster
# }

resource "google_container_cluster" "primary" {
  provider           = google-beta
  name               = "${var.gcp_project}-gke"
  location           = var.gcp_region
  network            = google_compute_network.vpc.name
  subnetwork         = google_compute_subnetwork.subnet.name
  logging_service    = "logging.googleapis.com/kubernetes"    # Lets use Stackdriver
  monitoring_service = "monitoring.googleapis.com/kubernetes" # Lets use Stackdriver

  enable_shielded_nodes       = true         # https://cloud.google.com/kubernetes-engine/docs/how-to/shielded-gke-nodes
  enable_intranode_visibility = true         # https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility
  networking_mode             = "VPC_NATIVE" # Required for private service networking to services

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
  remove_default_node_pool = false

  initial_node_count = var.gke_num_nodes

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
    env     = var.gcp_project
    mesh_id = "proj-${data.google_project.project.number}"
  }

  node_config {
    machine_type = var.node_type
    preemptible  = true # Don't want nodes failing during calls particularly
    disk_size_gb = var.node_disk_size
    disk_type    = var.node_disk_type
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.gcp_project
    }

    tags = ["gke-node", "${var.gcp_project}-gke"]

  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

# Separately Managed Node Pool
# resource "google_container_node_pool" "primary_nodes" {
#   name       = "${google_container_cluster.primary.name}-node-pool"
#   location   = var.gcp_region
#   cluster    = google_container_cluster.primary.name
#   node_count = var.gke_num_nodes

#   upgrade_settings {
#     max_surge       = 3
#     max_unavailable = 0
#   }

#   node_config {
#     service_account = google_service_account.cluster.email
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#       "https://www.googleapis.com/auth/cloud-platform",
#     ]

#     labels = {
#       env = var.gcp_project
#     }

#     preemptible  = true
#     machine_type = var.node_type
#     tags         = ["gke-node", "${var.gcp_project}-gke"]
#     metadata = {
#       disable-legacy-endpoints = "true"
#     }
#   }
# }