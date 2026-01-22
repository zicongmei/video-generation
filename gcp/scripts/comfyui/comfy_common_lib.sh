#!/bin/bash
# comfy_common_lib.sh - Common functions for ComfyUI setup on GCP L4

setup_serial_logging() {
    # Redirect all output and errors to serial port 2 (/dev/ttyS1) if it exists
    if [ -e /dev/ttyS1 ]; then
        sudo chmod 666 /dev/ttyS1
        exec > >(tee -a /dev/ttyS1) 2>&1
        echo "Output redirected to serial port 2 (/dev/ttyS1)"
    fi
}

install_system_dependencies() {
    echo "Installing system dependencies..."
    sudo apt-get update || true
    sudo apt-get install -y nginx git python3-pip openssl unzip wget aria2 $@
}

find_python310() {
    PYTHON_310="/opt/conda/bin/python"
    if [ ! -f "$PYTHON_310" ]; then
        PYTHON_310=$(which python3.10 || echo "/usr/bin/python3.10")
    fi
    if ! $PYTHON_310 --version &>/dev/null; then
        echo "Error: Python 3.10 not found."
        exit 1
    fi
    echo "$PYTHON_310"
}

setup_ssl_cert() {
    echo "Generating self-signed certificate..."
    sudo mkdir -p /etc/nginx/ssl
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"
}

install_comfyui_core() {
    local python_bin=$1
    echo "Installing ComfyUI core..."
    cd ~
    if [ ! -d "ComfyUI" ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git
    fi
    cd ComfyUI

    if [ ! -d "venv" ]; then
        $python_bin -m venv venv
    fi
    source venv/bin/activate
    pip install --upgrade pip
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    pip install -r requirements.txt
    pip install "huggingface_hub[cli,hf_transfer]" gguf
}

get_node() {
    local repo=$1
    local name=$2
    if [ ! -d "$name" ]; then
        echo "Fetching custom node: $name..."
        git clone --depth 1 "https://github.com/$repo/$name.git" || \
        (wget "https://github.com/$repo/$name/archive/refs/heads/main.zip" -O "${name}.zip" && \
         unzip "${name}.zip" && mv "${name}-main" "$name" && rm "${name}.zip")
    fi
    if [ -d "$name" ] && [ -f "$name/requirements.txt" ]; then
        pip install -r "$name/requirements.txt"
    fi
}

install_standard_nodes() {
    echo "Installing standard custom nodes..."
    export GIT_TERMINAL_PROMPT=0
    cd ~/ComfyUI/custom_nodes
    get_node "city96" "ComfyUI-GGUF"
    get_node "kijai" "ComfyUI-WanVideoWrapper"
    get_node "Kosinkadink" "ComfyUI-VideoHelperSuite"
    get_node "ltdrdata" "ComfyUI-Manager"
    cd ..
}

setup_systemd() {
    echo "Creating systemd service..."
    sudo tee /etc/systemd/system/comfyui.service <<EOF
[Unit]
Description=ComfyUI Backend
After=network.target nginx.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/ComfyUI
ExecStart=$HOME/ComfyUI/venv/bin/python main.py --listen 127.0.0.1 --highvram
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable comfyui
    sudo systemctl restart comfyui
}

