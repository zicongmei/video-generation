#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/text_encoders/mistral_3_small_flux2_bf16.safetensors", "url": "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors"},
    {"path": "/root/ComfyUI/models/loras/Flux_2-Turbo-LoRA_comfyui.safetensors", "url": "https://huggingface.co/ByteZSzn/Flux.2-Turbo-ComfyUI/resolve/main/Flux_2-Turbo-LoRA_comfyui.safetensors"},
    {"path": "/root/ComfyUI/models/diffusion_models/flux2_dev_fp8mixed.safetensors", "url": "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors"},
    {"path": "/root/ComfyUI/models/vae/flux2-vae.safetensors", "url": "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Flux 2 Dev..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae

echo "Downloading Flux 2 Dev: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/mistral_3_small_flux2_bf16.safetensors" "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/text_encoders/mistral_3_small_flux2_bf16.safetensors"

echo "Downloading Flux 2 Dev: LoRA..."
wget -c -O "/root/ComfyUI/models/loras/Flux_2-Turbo-LoRA_comfyui.safetensors" "https://huggingface.co/ByteZSzn/Flux.2-Turbo-ComfyUI/resolve/main/Flux_2-Turbo-LoRA_comfyui.safetensors"

echo "Downloading Flux 2 Dev: Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/flux2_dev_fp8mixed.safetensors" "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/diffusion_models/flux2_dev_fp8mixed.safetensors"

echo "Downloading Flux 2 Dev: VAE..."
wget -c -O "/root/ComfyUI/models/vae/flux2-vae.safetensors" "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"
