# The default VPC has no NAT by default, so a VM with no external IP (see
# compute.tf) has zero outbound internet access — apt/Docker Hub pulls and
# the Anthropic API calls all need egress. This gives outbound-only internet
# access without putting a public IP on the box.

resource "google_compute_router" "default" {
  name    = "colette-exec-router"
  project = var.project_id
  region  = var.region
  network = "default"
}

resource "google_compute_router_nat" "default" {
  name    = "colette-exec-nat"
  project = var.project_id
  router  = google_compute_router.default.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
