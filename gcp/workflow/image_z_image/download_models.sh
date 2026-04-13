#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"},
    {"path": "/root/ComfyUI/models/diffusion_models/z_image_bf16.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/diffusion_models/z_image_bf16.safetensors"},
    {"path": "/root/ComfyUI/models/vae/ae.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Z-Image..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/vae

echo "Downloading Z-Image: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
echo "Downloading Z-Image: Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/z_image_bf16.safetensors" "https://huggingface.co/Comfy-Org/z_image/resolve/main/split_files/diffusion_models/z_image_bf16.safetensors"
echo "Downloading Z-Image: VAE..."
wget -c -O "/root/ComfyUI/models/vae/ae.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
