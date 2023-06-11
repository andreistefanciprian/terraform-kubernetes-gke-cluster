# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.gcp_project}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.gcp_project}-subnet"
  region        = var.gcp_region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# Allow ssh into GKE nodes for debug purposes
# not recommended in production clusters
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["gke-node"]
}

# Allow istio pilot to inject sidecars
# needed by the Pilot discovery validation webhook
resource "google_compute_firewall" "allow_istio_auto_inject" {
  name    = "allow-istio-auto-inject"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["15017"]
  }

  source_ranges = [var.gke_master_cidr]

  target_tags = ["gke-node"]
}

# Allow internet connectivity from inside the cluster so we can pull images from public registries
# not recommended in production clusters
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
