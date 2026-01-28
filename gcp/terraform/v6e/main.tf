provider "google-beta" {
  project = var.project_id
}

resource "google_tpu_v2_vm" "tpu_vm" {
  provider          = google-beta
  name              = var.vm_name
  zone              = var.zone
  accelerator_type  = var.accelerator_type
  runtime_version   = var.runtime_version
  tags              = ["https-server"]

  network_config {
    can_ip_forward      = true
    enable_external_ips = true
  }

  scheduling_config {
    preemptible = var.use_spot
    reserved    = false
  }

  metadata = {
    auth_username = var.auth_username
    auth_password = var.auth_password
  }
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-tpu"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}