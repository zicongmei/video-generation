#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors", "url": "https://huggingface.co/Comfy-Org/flux2-klein/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Qwen-3 Text..."
mkdir -p /root/ComfyUI/models/text_encoders

echo "Downloading Qwen-3: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen_3_4b.safetensors" "https://huggingface.co/Comfy-Org/flux2-klein/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
