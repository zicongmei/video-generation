#!/bin/bash
set -e

# Fix for Bullseye backports 404 - DO THIS FIRST
sudo sed -i 's/.*bullseye-backports.*/# &/' /etc/apt/sources.list
if [ -d /etc/apt/sources.list.d ]; then
    sudo sed -i 's/.*bullseye-backports.*/# &/' /etc/apt/sources.list.d/*.list 2>/dev/null || true
fi

# Combined functions from comfy_common_lib.sh

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
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git python3-pip openssl unzip wget aria2 $@
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
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost" -batch
}

install_comfyui_core() {
    local python_bin=$1
    echo "Installing ComfyUI core..."
    cd /root
    if [ ! -d "ComfyUI" ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git
    fi
    cd ComfyUI

    if [ ! -d "venv" ]; then
        $python_bin -m venv venv
    fi
    source venv/bin/activate
    pip install --upgrade pip
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    pip install --no-cache-dir -r requirements.txt
    pip install --no-cache-dir "huggingface_hub[cli,hf_transfer]" gguf
}

setup_download_service() {
    echo "Creating dedicated venv for download service..."
    local python_bin=$(find_python310)
    sudo $python_bin -m venv /root/model_downloader_venv
    sudo /root/model_downloader_venv/bin/pip install --upgrade pip
    sudo /root/model_downloader_venv/bin/pip install --no-cache-dir fastapi uvicorn

    echo "Creating download service..."
    sudo tee /etc/systemd/system/comfyui-download.service <<'EOF'
[Unit]
Description=ComfyUI Download Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/root/model_downloader_venv/bin/python /root/download_service.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable comfyui-download
    sudo systemctl restart comfyui-download
}

get_node() {
    local repo=$1
    local name=$2
    if [ ! -d "$name" ]; then
        echo "Fetching custom node: $name..."
        git clone --depth 1 "https://github.com/$repo/$name.git" || 
        (wget "https://github.com/$repo/$name/archive/refs/heads/main.zip" -O "${name}.zip" && 
         unzip "${name}.zip" && mv "${name}-main" "$name" && rm "${name}.zip")
    fi
    if [ -d "$name" ] && [ -f "$name/requirements.txt" ]; then
        pip install --no-cache-dir -r "$name/requirements.txt"
    fi
}

install_standard_nodes() {
    echo "Installing standard custom nodes..."
    export GIT_TERMINAL_PROMPT=0
    cd /root/ComfyUI/custom_nodes
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
User=root
WorkingDirectory=/root/ComfyUI
ExecStart=/root/ComfyUI/venv/bin/python main.py --listen 127.0.0.1 --normalvram --verbose ERROR
Restart=always
RestartSec=10
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable comfyui
    sudo systemctl restart comfyui
}

# Main logic from setup_comfy_auth.sh

setup_serial_logging

echo "Starting setup (Authenticated) for ComfyUI on L4 GPU..."

# 1. Fetch credentials from metadata
echo "Fetching credentials from metadata..."
AUTH_USER=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_username)
AUTH_PASS=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_password)

# 2. Dependencies and cleanup
install_system_dependencies apache2-utils

echo "Cleaning up existing services on port 443..."
sudo systemctl stop comfyui-proxy || true
sudo fuser -k 443/tcp || true
sudo dpkg --configure -a || true
sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y || true

# 3. Environment and SSL
PYTHON_310=$(find_python310)
setup_ssl_cert

# 4. Auth File
echo "Creating authentication file for user: $AUTH_USER"
sudo htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"

# 5. Nginx Configuration

echo "Cleaning up conflicting Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/*

# Define Rate Limiting Zone
echo "Defining Nginx rate limiting zone..."
sudo tee /etc/nginx/conf.d/ratelimit.conf <<'EOF'
limit_req_zone $binary_remote_addr zone=comfy_limit:10m rate=1000r/s;
EOF

sudo tee /etc/nginx/sites-available/comfyui <<'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # Rate Limiting
    limit_req zone=comfy_limit burst=200 nodelay;

    # Allow large file uploads for models/images
    client_max_body_size 0;

    location /dl {
        return 301 /download;
    }

    location /download {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        # CORS Headers
        add_header 'Access-Control-Allow-Origin' '$http_origin' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;

        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '$http_origin' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://127.0.0.1:8188;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/comfyui /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

setup_download_service

# 6. ComfyUI Install
install_comfyui_core "$PYTHON_310"

echo "Pre-enabling Dev mode Options..."
sudo mkdir -p /root/ComfyUI/user/default
sudo tee /root/ComfyUI/user/default/comfy.settings.json <<EOF
{
    "Comfy.DevMode": true
}
EOF

install_standard_nodes
setup_systemd

echo "--------------------------------------------------------"
echo "Setup complete! Secured with Nginx Auth."
echo "URL: https://$(curl -s ifconfig.me)"
echo "Username: $AUTH_USER"
echo "--------------------------------------------------------"
