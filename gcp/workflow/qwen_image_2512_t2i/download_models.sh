#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors", "url": "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors", "url": "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"},
    {"path": "/root/ComfyUI/models/vae/qwen_image_vae.safetensors", "url": "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"},
    {"path": "/root/ComfyUI/models/loras/Qwen-Image-2512-Lightning-4steps-V1.0-fp32.safetensors", "url": "https://huggingface.co/lightx2v/Qwen-Image-2512-Lightning/resolve/main/Qwen-Image-2512-Lightning-4steps-V1.0-fp32.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for Qwen-Image-2512 T2I..."
mkdir -p /root/ComfyUI/models/diffusion_models /root/ComfyUI/models/text_encoders /root/ComfyUI/models/vae /root/ComfyUI/models/loras

echo "Downloading Qwen-Image-2512: Diffusion Model..."
wget -c -O "/root/ComfyUI/models/diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors" "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_2512_fp8_e4m3fn.safetensors"

echo "Downloading Qwen-Image-2512: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"

echo "Downloading Qwen-Image-2512: VAE..."
wget -c -O "/root/ComfyUI/models/vae/qwen_image_vae.safetensors" "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors"

echo "Downloading Qwen-Image-2512: LoRA (Lightning)..."
wget -c -O "/root/ComfyUI/models/loras/Qwen-Image-2512-Lightning-4steps-V1.0-fp32.safetensors" "https://huggingface.co/lightx2v/Qwen-Image-2512-Lightning/resolve/main/Qwen-Image-2512-Lightning-4steps-V1.0-fp32.safetensors"
