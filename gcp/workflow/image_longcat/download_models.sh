#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/diffusion_models/longcat_image_bf16.safetensors", "url": "https://huggingface.co/Comfy-Org/LongCat-Image/resolve/main/split_files/diffusion_models/longcat_image_bf16.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/vae/ae.safetensors", "url": "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Longcat..."
mkdir -p /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/text_encoders /root/ComfyUI/models/vae

echo "Downloading Longcat: Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/longcat_image_bf16.safetensors" "https://huggingface.co/Comfy-Org/LongCat-Image/resolve/main/split_files/diffusion_models/longcat_image_bf16.safetensors"
echo "Downloading Longcat: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/HunyuanVideo_1.5_repackaged/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
echo "Downloading Longcat: VAE..."
wget -c -O "/root/ComfyUI/models/vae/ae.safetensors" "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors"
