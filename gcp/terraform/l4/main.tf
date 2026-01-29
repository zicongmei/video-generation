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
    auth_username         = var.auth_username
    auth_password         = var.auth_password
  }

  metadata_startup_script = var.auto_deploy ? format("%s\n%s",
    file("${path.module}/../../scripts/comfyui/setup_comfy_all_in_one.sh"),
    var.model_download ? <<-EOT
      # Download models if requested
      echo "Downloading models for ComfyUI..."
      mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae /root/ComfyUI/models/checkpoints /root/ComfyUI/models/latent_upscale_models

      # Z-Image-Turbo
      wget -c -O /root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
      wget -c -O /root/ComfyUI/models/loras/pixel_art_style_z_image_turbo.safetensors "https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo/resolve/main/pixel_art_style_z_image_turbo.safetensors"
      wget -c -O /root/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
      wget -c -O /root/ComfyUI/models/vae/ae.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"

      # LTX-2
      wget -c -O /root/ComfyUI/models/checkpoints/ltx-2-19b-dev-fp8.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors"
      wget -c -O /root/ComfyUI/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"
      wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-distilled-lora-384.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors"
      wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors "https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors"
      wget -c -O /root/ComfyUI/models/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors"

      # Wan 2.2
      wget -c -O /root/ComfyUI/models/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
      wget -c -O /root/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
      wget -c -O /root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
      wget -c -O /root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
      wget -c -O /root/ComfyUI/models/vae/wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
      wget -c -O /root/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
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
