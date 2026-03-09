#!/bin/bash

MODELS=(
    "/root/ComfyUI/models/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
    "/root/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
    "/root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
    "/root/ComfyUI/models/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
    "/root/ComfyUI/models/vae/wan_2.1_vae.safetensors"
    "/root/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

if [ "$1" == "--list" ]; then
    for model in "${MODELS[@]}"; do
        echo "$model"
    done
    exit 0
fi

echo "Downloading models for Wan 2.2 T2V..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae

echo "Downloading Wan 2.2 T2V: Diffusion Model (High Noise)..."
wget -c -O "${MODELS[0]}" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp8_scaled.safetensors"
echo "Downloading Wan 2.2 T2V: Diffusion Model (Low Noise)..."
wget -c -O "${MODELS[1]}" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp8_scaled.safetensors"
echo "Downloading Wan 2.2 T2V: LoRA (High Noise)..."
wget -c -O "${MODELS[2]}" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_high_noise.safetensors"
echo "Downloading Wan 2.2 T2V: LoRA (Low Noise)..."
wget -c -O "${MODELS[3]}" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"

# Common Wan 2.2 models
echo "Downloading Wan 2.2: VAE..."
wget -c -O "${MODELS[4]}" "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
echo "Downloading Wan 2.2: Text Encoder..."
wget -c -O "${MODELS[5]}" "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
