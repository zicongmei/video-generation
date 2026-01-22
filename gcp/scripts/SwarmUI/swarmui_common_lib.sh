#!/bin/bash
# swarmui_common_lib.sh - Common functions for SwarmUI setup on GCP

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
    sudo apt-get install -y nginx git openssl unzip wget aria2 apache2-utils python3-venv python3-pip $@
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

install_swarmui() {
    echo "Installing Dotnet 8.0 SDK..."
    # Following Microsoft's guide for Debian 11
    wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update || true
    sudo apt-get install -y dotnet-sdk-8.0

    echo "Installing SwarmUI via git clone..."
    cd ~
    if [ ! -d "SwarmUI" ]; then
        git clone https://github.com/mcmonkeyprojects/SwarmUI.git
    fi
    cd SwarmUI
    chmod +x launch-linux.sh

    echo "Installing missing Python dependencies for SwarmUI backend..."
    local PYTHON_310=$(find_python310)
    sudo $PYTHON_310 -m pip install torchsde sqlalchemy tqdm psutil pillow numpy scipy aiohttp yarl pyyaml transformers tokenizers safetensors torchaudio comfy-kitchen
}

setup_systemd() {
    echo "Creating systemd service for SwarmUI..."
    # SwarmUI by default installs to ~/SwarmUI
    # It uses a launch script ./launch-linux.sh
    sudo tee /etc/systemd/system/swarmui.service <<EOF
[Unit]
Description=SwarmUI Backend
After=network.target nginx.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/SwarmUI
ExecStart=$HOME/SwarmUI/launch-linux.sh --launch_mode none --host 127.0.0.1 --port 7801
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable swarmui
    sudo systemctl restart swarmui
}
