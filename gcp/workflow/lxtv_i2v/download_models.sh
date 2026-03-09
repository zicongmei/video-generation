#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/checkpoints/ltx-video-2b-v0.9.5.safetensors", "url": "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.5.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/t5xxl_fp16.safetensors", "url": "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for LTX-Video I2V..."
mkdir -p /root/ComfyUI/models/checkpoints /root/ComfyUI/models/text_encoders

echo "Downloading LTX-Video: Checkpoint..."
wget -c -O "/root/ComfyUI/models/checkpoints/ltx-video-2b-v0.9.5.safetensors" "https://huggingface.co/Lightricks/LTX-Video/resolve/main/ltx-video-2b-v0.9.5.safetensors"

echo "Downloading LTX-Video: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/t5xxl_fp16.safetensors" "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"
