provider "google" {
  project = var.project_id
}

resource "google_compute_instance" "vm_instance" {
  name         = var.vm_name
  machine_type = "g2-standard-8" # 8 vCPUs, 32GB RAM, 1 L4 GPU
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
    auth_username         = var.auth_username
    auth_password         = var.auth_password
  }

  metadata_startup_script = var.auto_deploy ? format("%s\n%s",
    file("${path.module}/../../scripts/comfyui/setup_comfy_all_in_one.sh"),
    var.download_models ? <<-EOT
      # Download models if requested
      echo "Downloading models for ComfyUI..."
      mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae

      wget -O /root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
      wget -O /root/ComfyUI/models/loras/pixel_art_style_z_image_turbo.safetensors "https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo/resolve/main/pixel_art_style_z_image_turbo.safetensors"
      wget -O /root/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
      wget -O /root/ComfyUI/models/vae/ae.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
    EOT
    : ""
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
