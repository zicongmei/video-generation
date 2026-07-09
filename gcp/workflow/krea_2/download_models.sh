#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/diffusion_models/krea2_turbo_int8_convrot.safetensors", "url": "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/diffusion_models/krea2_turbo_int8_convrot.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/qwen3vl_4b_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/vae/qwen_image_vae.safetensors", "url": "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors"},
    {"path": "/root/ComfyUI/models/loras/krea2_darkbrush.safetensors", "url": "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/loras/krea2_darkbrush.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Krea-2..."
mkdir -p /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/text_encoders /root/ComfyUI/models/vae /root/ComfyUI/models/loras

echo "Downloading Krea-2: Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/krea2_turbo_int8_convrot.safetensors" "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/diffusion_models/krea2_turbo_int8_convrot.safetensors"

echo "Downloading Krea-2: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen3vl_4b_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors"

echo "Downloading Krea-2: VAE..."
wget -c -O "/root/ComfyUI/models/vae/qwen_image_vae.safetensors" "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors"

echo "Downloading Krea-2: LoRA..."
wget -c -O "/root/ComfyUI/models/loras/krea2_darkbrush.safetensors" "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/loras/krea2_darkbrush.safetensors"
