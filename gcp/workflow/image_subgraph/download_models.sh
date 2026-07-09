#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/text_encoders/qwen_3_4b_fp8_mixed.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b_fp8_mixed.safetensors"},
    {"path": "/root/ComfyUI/models/vae/ae.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"},
    {"path": "/root/ComfyUI/models/diffusion_models/z_image_turbo_int8_convrot.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_int8_convrot.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Z-Image-Turbo (Int8/Subgraph)..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/vae /root/ComfyUI/models/diffusion_models

echo "Downloading Z-Image-Turbo (Int8): Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen_3_4b_fp8_mixed.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b_fp8_mixed.safetensors"

echo "Downloading Z-Image-Turbo (Int8): VAE..."
wget -c -O "/root/ComfyUI/models/vae/ae.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"

echo "Downloading Z-Image-Turbo (Int8): Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/z_image_turbo_int8_convrot.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_int8_convrot.safetensors"
