#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/checkpoints/hidream_o1_image_bf16.safetensors", "url": "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_bf16.safetensors"},
    {"path": "/root/ComfyUI/models/checkpoints/hidream_o1_image_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/checkpoints/hidream_o1_image_mxfp8.safetensors", "url": "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_mxfp8.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for HiDream-O1-Image..."
mkdir -p /root/ComfyUI/models/checkpoints /root/ComfyUI/models/text_encoders

echo "Downloading HiDream-O1-Image: Checkpoints..."
wget -c -O "/root/ComfyUI/models/checkpoints/hidream_o1_image_bf16.safetensors" "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_bf16.safetensors"
wget -c -O "/root/ComfyUI/models/checkpoints/hidream_o1_image_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_fp8_scaled.safetensors"
wget -c -O "/root/ComfyUI/models/checkpoints/hidream_o1_image_mxfp8.safetensors" "https://huggingface.co/Comfy-Org/HiDream-O1-Image/resolve/main/checkpoints/hidream_o1_image_mxfp8.safetensors"

echo "Downloading HiDream-O1-Image: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors"
