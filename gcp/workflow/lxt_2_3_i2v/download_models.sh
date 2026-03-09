#!/bin/bash

if [ "$1" == "--list" ]; then
    cat << 'EOF'
[
    {"path": "/root/ComfyUI/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.0.safetensors", "url": "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.0.safetensors"},
    {"path": "/root/ComfyUI/models/checkpoints/ltx-2.3-22b-dev-fp8.safetensors", "url": "https://huggingface.co/Lightricks/LTX-2.3-fp8/resolve/main/ltx-2.3-22b-dev-fp8.safetensors"},
    {"path": "/root/ComfyUI/models/loras/ltx-2.3-22b-distilled-lora-384.safetensors", "url": "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-distilled-lora-384.safetensors"},
    {"path": "/root/ComfyUI/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors", "url": "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"}
]
EOF
    exit 0
fi

echo "Downloading models for LTX-2.3 I2V..."
mkdir -p /root/ComfyUI/models/latent_upscale_models /root/ComfyUI/models/checkpoints /root/ComfyUI/models/loras /root/ComfyUI/models/text_encoders

echo "Downloading LTX-2.3: Spatial Upscaler..."
wget -c -O "/root/ComfyUI/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.0.safetensors" "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.0.safetensors"

echo "Downloading LTX-2.3: Checkpoint (FP8)..."
wget -c -O "/root/ComfyUI/models/checkpoints/ltx-2.3-22b-dev-fp8.safetensors" "https://huggingface.co/Lightricks/LTX-2.3-fp8/resolve/main/ltx-2.3-22b-dev-fp8.safetensors"

echo "Downloading LTX-2.3: LoRA (Distilled)..."
wget -c -O "/root/ComfyUI/models/loras/ltx-2.3-22b-distilled-lora-384.safetensors" "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-distilled-lora-384.safetensors"

echo "Downloading LTX-2.3: Text Encoder..."
wget -c -O "/root/ComfyUI/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors" "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"
