#!/bin/bash
set -e

# Configuration
INSTALL_DIR="$HOME/ComfyUI"
PYTHON_BIN="python3.12"

install_system_dependencies() {
    echo "Installing system dependencies..."
    sudo apt-get update || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git python3.12-venv python3.12-dev python3-pip openssl unzip wget aria2 apache2-utils
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
    echo "Installing ComfyUI core..."
    cd ~
    if [ ! -d "ComfyUI" ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git
    fi
    cd ComfyUI

    if [ ! -d "venv" ]; then
        $PYTHON_BIN -m venv venv
    fi
    source venv/bin/activate
    pip install --upgrade pip
    pip install packaging
    
    echo "Installing PyTorch with TPU support (torch_xla)..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install torch_xla[tpu] -f https://storage.googleapis.com/libtpu-releases/index.html

    pip install -r requirements.txt
}

get_node() {
    local repo=$1
    local name=$2
    if [ ! -d "custom_nodes/$name" ]; then
        echo "Fetching custom node: $name..."
        git clone --depth 1 "https://github.com/$repo/$name.git" "custom_nodes/$name"
    fi
    if [ -d "custom_nodes/$name" ] && [ -f "custom_nodes/$name/requirements.txt" ]; then
        source venv/bin/activate
        pip install -r "custom_nodes/$name/requirements.txt"
    fi
}

install_standard_nodes() {
    echo "Installing custom nodes..."
    cd ~/ComfyUI
    get_node "ltdrdata" "ComfyUI-Manager"
    get_node "kijai" "ComfyUI-WanVideoWrapper"
    get_node "Kosinkadink" "ComfyUI-VideoHelperSuite"
    get_node "city96" "ComfyUI-GGUF"
}

setup_nginx() {
    echo "Setting up Nginx with Basic Auth and CORS (L4 GPU Parity)..."
    AUTH_USER=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_username || echo "admin")
    AUTH_PASS=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_password || echo "admin")

    if [[ "$AUTH_USER" == *"html"* ]] || [ -z "$AUTH_USER" ]; then AUTH_USER="admin"; fi
    if [[ "$AUTH_PASS" == *"html"* ]] || [ -z "$AUTH_PASS" ]; then AUTH_PASS="admin"; fi

    echo "Using username: $AUTH_USER"
    sudo htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"

    sudo tee /etc/nginx/sites-available/comfyui <<'EOF'
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    client_max_body_size 0;

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
}

setup_systemd() {
    echo "Creating systemd service..."
    sudo tee /etc/systemd/system/comfyui.service <<EOF
[Unit]
Description=ComfyUI TPU Backend
After=network.target nginx.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/ComfyUI
Environment="PJRT_DEVICE=TPU"
Environment="XLA_USE_BF16=1"
ExecStart=$HOME/ComfyUI/venv/bin/python main.py --listen 127.0.0.1 --cpu
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable comfyui
    sudo systemctl restart comfyui
}

install_system_dependencies
setup_ssl_cert
install_comfyui_core
install_standard_nodes
setup_nginx
setup_systemd

echo "ComfyUI TPU Setup complete with Nginx Auth and CORS parity!"