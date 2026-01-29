#!/bin/bash

# Redirect output to serial port 2 (/dev/ttyS1) if it exists
if [ -e /dev/ttyS1 ]; then
    sudo chmod 666 /dev/ttyS1
    exec > >(tee -a /dev/ttyS1) 2>&1
    echo "Output redirected to serial port 2 (/dev/ttyS1)"
fi

echo "Downloading models for ComfyUI..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae /root/ComfyUI/models/checkpoints /root/ComfyUI/models/latent_upscale_models

# Z-Image-Turbo
echo "Downloading Z-Image-Turbo: Text Encoder..."
wget -c -O /root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
echo "Downloading Z-Image-Turbo: LoRA..."
wget -c -O /root/ComfyUI/models/loras/pixel_art_style_z_image_turbo.safetensors "https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo/resolve/main/pixel_art_style_z_image_turbo.safetensors"
echo "Downloading Z-Image-Turbo: Diffusion Model..."
wget -c -O /root/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
echo "Downloading Z-Image-Turbo: VAE..."
wget -c -O /root/ComfyUI/models/vae/ae.safetensors "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"

# LTX-2
echo "Downloading LTX-2: Checkpoint..."
wget -c -O /root/ComfyUI/models/checkpoints/ltx-2-19b-dev-fp8.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors"
echo "Downloading LTX-2: Text Encoder..."
wget -c -O /root/ComfyUI/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"
echo "Downloading LTX-2: LoRA (Distilled)..."
wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-distilled-lora-384.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors"
echo "Downloading LTX-2: LoRA (Camera Control Dolly Left)..."
wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors "https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors"
echo "Downloading LTX-2: Spatial Upscaler..."
wget -c -O /root/ComfyUI/models/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors"

# Wan 2.2
echo "Downloading Wan 2.2: Diffusion Model (High Noise)..."
wget -c -O /root/ComfyUI/models/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
echo "Downloading Wan 2.2: Diffusion Model (Low Noise)..."
wget -c -O /root/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
echo "Downloading Wan 2.2: LoRA (High Noise)..."
wget -c -O /root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
echo "Downloading Wan 2.2: LoRA (Low Noise)..."
wget -c -O /root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
echo "Downloading Wan 2.2: VAE..."
wget -c -O /root/ComfyUI/models/vae/wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
echo "Downloading Wan 2.2: Text Encoder..."
wget -c -O /root/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
