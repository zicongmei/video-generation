# Wan 2.2 I2V Generator Web Interface

A simple web interface for generating videos from images using the Wan 2.2 I2V workflow in ComfyUI.

[Tutorial](https://docs.comfy.org/tutorials/video/wan/wan2_2)

## Directory Structure

- `index.html`: The main user interface.
- `resource/`:
    - `workflow.json`: The ComfyUI workflow in **API Format**.
    - `script.js`: Frontend logic for video generation.
    - `style.css`: UI styling.

## Model Information

These models are required for the workflow to function:

**Diffusion Model**
- [wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors)
- [wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors)

**LoRA**
- [wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors)
- [wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors)

**VAE**
- [wan_2.1_vae.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors)

**Text Encoder**   
- [umt5_xxl_fp8_e4m3fn_scaled.safetensors](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors)

### Model Storage Location

Ensure models are placed in the correct directories within your ComfyUI installation:

```text
ComfyUI/
├───📂 models/
│   ├───📂 diffusion_models/
│   │   ├─── wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors
│   │   └─── wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
│   ├───📂 loras/
│   │   ├─── wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors
│   │   └─── wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors
│   ├───📂 text_encoders/
│   │   └─── umt5_xxl_fp8_e4m3fn_scaled.safetensors 
│   └───📂 vae/
│       └── wan_2.1_vae.safetensors
```

### Download Script (wget)

```bash
# Set your ComfyUI models path
MODELS_DIR="/root/ComfyUI/models"

# Download Diffusion Models
wget -c -P "$MODELS_DIR/diffusion_models/" https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors
wget -c -P "$MODELS_DIR/diffusion_models/" https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors

# Download LoRAs
wget -c -P "$MODELS_DIR/loras/" https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors
wget -c -P "$MODELS_DIR/loras/" https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors

# Download Text Encoder
wget -c -P "$MODELS_DIR/text_encoders/" https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

# Download VAE
wget -c -P "$MODELS_DIR/vae/" https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors
```

## Quick Start

### 1. Start a Local Web Server
```bash
cd gcp/workflow/video_wan2_2_14B_i2v
python3 -m http.server 8003
```

### 2. Pre-Authenticate with the Backend
Navigate to `https://[YOUR_VM_IP]` in a separate tab and log in.

### 3. Access the Interface
Navigate to `http://localhost:8003/index.html`.

## Features
- **Image Upload**: Upload a reference image for the I2V process.
- **Sidebar History**: All generated videos are stored locally in IndexedDB.
- **Interactive Thumbnails**: Click a thumbnail to reload parameters and play the video.
- **Advanced Settings**: Control width, height, frame count, FPS, and seed.
- **Debug Mode**: Inspect API requests and responses.
