# LTX-2 Video Generator Web Interface

A simple web interface for generating videos using the LTX-2 workflow in ComfyUI.

## Directory Structure

- `index.html`: The main user interface.
- `resource/`:
    - `workflow.json`: The ComfyUI workflow in **API Format**.
    - `script.js`: Frontend logic for video generation.
    - `style.css`: UI styling.

## Model Information

## Model links (for local users)

**checkpoints**
- [ltx-2-19b-dev-fp8.safetensors](https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors)

**text_encoders**

- [gemma_3_12B_it_fp4_mixed.safetensors](https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors)

**loras**

- [ltx-2-19b-distilled-lora-384.safetensors](https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors)
- [ltx-2-19b-lora-camera-control-dolly-left.safetensors](https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors)

**latent_upscale_models**

- [ltx-2-spatial-upscaler-x2-1.0.safetensors](https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors)

### Model Storage Location

Ensure models are placed in the correct directories within your ComfyUI installation:

```text
📂 ComfyUI/
├── 📂 models/
│   ├── 📂 checkpoints/
│   │      └── ltx-2-19b-dev-fp8.safetensors
│   ├── 📂 text_encoders/
│   │      └── gemma_3_12B_it_fp4_mixed.safetensors
│   ├── 📂 loras/
│   │      ├── ltx-2-19b-distilled-lora-384.safetensors
│   │      └── ltx-2-19b-lora-camera-control-dolly-left.safetensors
│   └── 📂 latent_upscale_models/
│          └── ltx-2-spatial-upscaler-x2-1.0.safetensors
```

## Quick Start

### 1. Start a Local Web Server
```bash
cd gcp/workflow/ltx2_t2v
python3 -m http.server 8001
```

### 2. Pre-Authenticate with the Backend
Navigate to `https://[YOUR_VM_IP]` in a separate tab and log in.

### 3. Access the Interface
Navigate to `http://localhost:8001/index.html`.

## Features
- **Sidebar History**: All generated videos are stored locally in IndexedDB.
- **Interactive Thumbnails**: Click a thumbnail to reload the prompt and play the video.
- **Advanced Settings**: Control width, height, frame count, FPS, and seed.
- **Debug Mode**: Inspect API requests and responses.
