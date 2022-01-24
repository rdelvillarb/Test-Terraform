# VPC
resource "google_compute_network" "vpc" {
  name                    = "${local.project_id}-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
  mtu                     = 1500
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${local.project_id}-subnet"
  region        = local.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}