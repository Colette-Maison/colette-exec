# Single VM in the project's default VPC (deliberately NOT colette-vpc,
# which exists for the family product's Cloud SQL private-IP path — this app
# doesn't touch Cloud SQL, so there's no reason to share that network).
#
# No external IP. Reached for setup/ops via IAP TCP tunneling
# (`gcloud compute ssh --tunnel-through-iap`), matching docker-compose.yml's
# own "API on loopback, front the UI with something real" posture. Public
# reachability for West/Wolf/Dingus (domain + TLS in front of the UI) is a
# Phase 3 decision, not wired up here.

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "colette-exec-allow-iap-ssh"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's fixed TCP-forwarding range — not the open internet.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["colette-exec"]
}

resource "google_compute_instance" "app" {
  name         = "colette-exec"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = ["colette-exec"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    # No access_config block => no external IP.
  }

  service_account {
    email  = google_service_account.app.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")
}
