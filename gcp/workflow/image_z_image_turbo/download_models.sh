#!/bin/bash

MODELS=(
    "/root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors"
    "/root/ComfyUI/models/loras/pixel_art_style_z_image_turbo.safetensors"
    "/root/ComfyUI/models/diffusion_models/z_image_turbo_bf16.safetensors"
    "/root/ComfyUI/models/vae/ae.safetensors"
)

if [ "$1" == "--list" ]; then
    for model in "${MODELS[@]}"; do
        echo "$model"
    done
    exit 0
fi

echo "Downloading models for Z-Image-Turbo..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae

echo "Downloading Z-Image-Turbo: Text Encoder..."
wget -c -O "${MODELS[0]}" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
echo "Downloading Z-Image-Turbo: LoRA..."
wget -c -O "${MODELS[1]}" "https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo/resolve/main/pixel_art_style_z_image_turbo.safetensors"
echo "Downloading Z-Image-Turbo: Diffusion Model..."
wget -c -O "${MODELS[2]}" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
echo "Downloading Z-Image-Turbo: VAE..."
wget -c -O "${MODELS[3]}" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
