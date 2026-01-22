#!/bin/bash
# pinokio_common_lib.sh - Common functions for Pinokio setup on GCP

setup_serial_logging() {
    if [ -e /dev/ttyS1 ]; then
        sudo chmod 666 /dev/ttyS1
        exec > >(tee -a /dev/ttyS1) 2>&1
        echo "Output redirected to serial port 2 (/dev/ttyS1)"
    fi
}

install_system_dependencies() {
    echo "Fixing broken APT repositories..."
    sudo sed -i 's/^deb.*bullseye-backports/# &/' /etc/apt/sources.list || true
    
    echo "Installing system dependencies..."
    sudo apt-get update || true
    sudo apt-get install -y nginx git openssl unzip wget aria2 apache2-utils curl $@
    
    # Install Node.js (v20)
    if ! command -v node &> /dev/null || [[ $(node -v) == v12* ]]; then
        echo "Installing Node.js v20..."
        # Remove existing old nodejs if present
        sudo apt-get remove -y nodejs libnode72 || true
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
}

setup_ssl_cert() {
    echo "Generating self-signed certificate..."
    sudo mkdir -p /etc/nginx/ssl
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"
}

install_pinokio() {
    echo "Installing Pinokio daemon (pinokiod) via npm..."
    # pinokiod is the server-side version of Pinokio, ideal for headless VMs
    sudo npm install -g pinokiod
}

setup_systemd() {
    echo "Creating systemd service for Pinokio..."
    # Find the global node_modules path
    local NODE_MOD_PATH=$(npm root -g)
    local PINOKIOD_PATH="${NODE_MOD_PATH}/pinokiod/script/index.js"
    
    sudo tee /etc/systemd/system/pinokio.service <<EOF
[Unit]
Description=Pinokio Daemon
After=network.target nginx.service

[Service]
Type=simple
User=root
WorkingDirectory=/root
# Using the pinokiod server entry point
ExecStart=/usr/bin/node ${PINOKIOD_PATH}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable pinokio
    sudo systemctl restart pinokio
}

