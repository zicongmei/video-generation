#!/bin/bash
echo "Downloading models for LTX-2..."
mkdir -p /root/ComfyUI/models/text_encoders /root/ComfyUI/models/loras /root/ComfyUI/models/checkpoints /root/ComfyUI/models/latent_upscale_models

echo "Downloading LTX-2: Checkpoint..."
wget -c -O /root/ComfyUI/models/checkpoints/ltx-2-19b-dev-fp8.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors"
echo "Downloading LTX-2: Text Encoder..."
wget -c -O /root/ComfyUI/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors"
echo "Downloading LTX-2: LoRA (Distilled)..."
wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-distilled-lora-384.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors"
echo "Downloading LTX-2: LoRA (Camera Control Dolly Left)..."
wget -c -O /root/ComfyUI/models/loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors "https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors"
echo "Downloading LTX-2: Spatial Upscaler..."
wget -c -O /root/ComfyUI/models/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors"
