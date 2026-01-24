FROM ghcr.io/ai-dock/comfyui:latest-cuda

# Install dependencies for ComfyUI-GGUF
RUN pip install gguf

# Following get_node method from comfy_common_lib.sh
RUN cd /opt/ComfyUI/custom_nodes && \
    (git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git || \
    (wget https://github.com/city96/ComfyUI-GGUF/archive/refs/heads/main.zip -O ComfyUI-GGUF.zip && \
     unzip ComfyUI-GGUF.zip && mv ComfyUI-GGUF-main ComfyUI-GGUF && rm ComfyUI-GGUF.zip)) && \
    if [ -f ComfyUI-GGUF/requirements.txt ]; then \
        pip install -r ComfyUI-GGUF/requirements.txt; \
    fi