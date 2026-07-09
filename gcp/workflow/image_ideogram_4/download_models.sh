#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/vae/flux2-vae.safetensors", "url": "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"},
    {"path": "/root/ComfyUI/models/diffusion_models/ideogram4_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/Ideogram-4/resolve/main/diffusion_models/ideogram4_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/diffusion_models/ideogram4_unconditional_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/Ideogram-4/resolve/main/diffusion_models/ideogram4_unconditional_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/qwen3vl_8b_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_8b_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Ideogram-4..."
mkdir -p /root/ComfyUI/models/vae /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/text_encoders

echo "Downloading Ideogram-4: VAE..."
wget -c -O "/root/ComfyUI/models/vae/flux2-vae.safetensors" "https://huggingface.co/Comfy-Org/flux2-dev/resolve/main/split_files/vae/flux2-vae.safetensors"

echo "Downloading Ideogram-4: Diffusion Models..."
wget -c -O "/root/ComfyUI/models/diffusion_models/ideogram4_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Ideogram-4/resolve/main/diffusion_models/ideogram4_fp8_scaled.safetensors"
wget -c -O "/root/ComfyUI/models/diffusion_models/ideogram4_unconditional_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Ideogram-4/resolve/main/diffusion_models/ideogram4_unconditional_fp8_scaled.safetensors"

echo "Downloading Ideogram-4: Text Encoders..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen3vl_8b_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_8b_fp8_scaled.safetensors"
wget -c -O "/root/ComfyUI/models/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors"
