provider "google" {
  project = var.project_id
}

resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["https-server"]

  boot_disk {
    initialize_params {
      image = "projects/ml-images/global/images/c0-deeplearning-common-cu124-v20250325-debian-11-py310-conda"
      size  = var.disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  guest_accelerator {
    type  = "nvidia-l4"
    count = 1
  }

  metadata = {
    install-nvidia-driver = "True"
    serial-port-logging-enable = "true"
    auth_username         = var.auth_username
    auth_password         = var.auth_password
  }

  metadata_startup_script = var.auto_deploy ? format("%s\n%s\n%s",
    file("${path.module}/../../scripts/comfyui/setup_comfy_all_in_one.sh"),
    var.model_download ? file("${path.module}/../../scripts/comfyui/download_models.sh") : "",
    "echo 'Startup script finished'"
  ) : null

  scheduling {
    on_host_maintenance = "TERMINATE" # Required for GPU instances
    provisioning_model  = var.use_spot ? "SPOT" : "STANDARD"
    preemptible         = var.use_spot ? true : false
    automatic_restart   = var.use_spot ? false : true
  }
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}
