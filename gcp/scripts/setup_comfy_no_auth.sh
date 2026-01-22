#!/bin/bash
set -e

# Load common library
source $(dirname "$0")/comfy_common_lib.sh

setup_serial_logging

echo "Starting setup (No Auth) for ComfyUI on L4 GPU..."

# 1. Environment and Dependencies
install_system_dependencies
PYTHON_310=$(find_python310)
setup_ssl_cert

# 2. Nginx Configuration
sudo tee /etc/nginx/sites-available/comfyui <<'EOF'
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    location / {
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

# 3. ComfyUI Install
install_comfyui_core "$PYTHON_310"
install_standard_nodes
setup_systemd

echo "--------------------------------------------------------"
echo "Setup complete! ComfyUI is ready (No Auth)."
echo "URL: https://$(curl -s ifconfig.me)"
echo "--------------------------------------------------------"
