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

  metadata_startup_script = var.auto_deploy ? format("%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s",
    "cat <<'EOF_PYTHON' > /root/download_service.py\n${file("${path.module}/../../scripts/comfyui/download_service.py")}\nEOF_PYTHON",
    "mkdir -p /root/models_download",
    "cat <<'EOF_Z_IMAGE' > /root/models_download/z_image_turbo.sh\n${file("${path.module}/../../workflow/image_z_image_turbo/download_models.sh")}\nEOF_Z_IMAGE",
    "cat <<'EOF_LTX2' > /root/models_download/ltx2_t2v.sh\n${file("${path.module}/../../workflow/ltx2_t2v/download_models.sh")}\nEOF_LTX2",
    "cat <<'EOF_LTX23_I2V' > /root/models_download/lxt_2_3_i2v.sh\n${file("${path.module}/../../workflow/lxt_2_3_i2v/download_models.sh")}\nEOF_LTX23_I2V",
    "cat <<'EOF_WAN_T2V' > /root/models_download/video_wan2_2_14B_t2v.sh\n${file("${path.module}/../../workflow/video_wan2_2_14B_t2v/download_models.sh")}\nEOF_WAN_T2V",
    "cat <<'EOF_WAN_I2V' > /root/models_download/video_wan2_2_14B_i2v.sh\n${file("${path.module}/../../workflow/video_wan2_2_14B_i2v/download_models.sh")}\nEOF_WAN_I2V",
    "chmod +x /root/models_download/*.sh",
    file("${path.module}/../../scripts/comfyui/setup_comfy_all_in_one.sh"),
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
