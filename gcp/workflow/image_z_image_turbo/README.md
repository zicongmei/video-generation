# Z-Image-Turbo Simple Web Interface

A simple, lightweight web interface to interact with the Z-Image-Turbo ComfyUI workflow.

## Directory Structure

- `index.html`: The main user interface.
- `resource/`:
    - `workflow.json`: The ComfyUI workflow in **API Format**.
    - `script.js`: Frontend logic for communicating with ComfyUI.
    - `style.css`: UI styling.

## Model Information

These models are required for the workflow to function:

- **Text Encoder**: [qwen_3_4b.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors)
- **LoRA**: [pixel_art_style_z_image_turbo.safetensors](https://huggingface.co/tarn59/pixel_art_style_lora_z_image_turbo/resolve/main/pixel_art_style_z_image_turbo.safetensors)
- **Diffusion Model**: [z_image_turbo_bf16.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors)
- **VAE**: [ae.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors)

### Model Storage Location

Ensure models are placed in the correct directories within your ComfyUI installation:

```text
📂 ComfyUI/
├── 📂 models/
│   ├── 📂 text_encoders/
│   │      └── qwen_3_4b.safetensors
│   ├── 📂 loras/
│   │      └── pixel_art_style_z_image_turbo.safetensors
│   ├── 📂 diffusion_models/
│   │      └── z_image_turbo_bf16.safetensors
│   └── 📂 vae/
│          └── ae.safetensors
```

## Prerequisites

1.  **ComfyUI Backend**: A running ComfyUI instance (e.g., your GCP L4 VM).
2.  **API Format Workflow**: The `resource/workflow.json` MUST be in ComfyUI's **API Format**.
    - Open ComfyUI -> Settings -> Enable "Dev mode Options".
    - Click "Save (API Format)" and save as `resource/workflow.json`.

## Quick Start

### 1. Start a Local Web Server
Browsers block file requests when opening HTML files directly from disk. You must serve these files via HTTP.

In your terminal:
```bash
cd gcp/workflow/image_z_image_turbo
python3 -m http.server 8000
```

### 2. Pre-Authenticate with the Backend
Because the VM uses a self-signed certificate and Basic Authentication:
1.  Open a new browser tab and navigate to: `https://[YOUR_VM_IP]`
2.  Accept the SSL certificate warning (**Advanced** -> **Proceed**).
3.  Log in with your `auth_username` and `auth_password`.

### 3. Access the Interface
1.  Navigate to: `http://localhost:8000/index.html`
2.  Enter your **VM IP** in the server configuration box.
3.  Type a prompt and click **Generate Image**.

## Troubleshooting

-   **CORS Policy Error**: Ensure you have run the Nginx configuration update on the VM to allow cross-origin requests.
-   **API Format Error**: If you see an error about "UI format detected", you are using a standard ComfyUI save file instead of the "API Format" export.
-   **Mixed Content**: If you are using port 443 (HTTPS) on the VM but serving the local page via `http`, some browsers may block the connection. Always ensure you have "pre-authenticated" by visiting the VM IP directly first.
