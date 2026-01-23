#!/bin/bash
set -e

# Load common library
source $(dirname "$0")/comfy_common_lib.sh

setup_serial_logging

echo "Starting setup (Authenticated) for ComfyUI on L4 GPU..."

# 1. Fetch credentials from metadata
echo "Fetching credentials from metadata..."
AUTH_USER=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_username || echo "root")
AUTH_PASS=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_password || echo "qps564")

# 2. Dependencies and cleanup
install_system_dependencies apache2-utils

echo "Cleaning up existing services on port 443..."
sudo systemctl stop comfyui-proxy || true
sudo fuser -k 443/tcp || true
sudo dpkg --configure -a || true
sudo apt-get install -f -y || true

# 3. Environment and SSL
PYTHON_310=$(find_python310)
setup_ssl_cert

# 4. Auth File
echo "Creating authentication file for user: $AUTH_USER"
sudo htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"

# 5. Nginx Configuration

echo "Cleaning up conflicting Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/*

sudo tee /etc/nginx/sites-available/comfyui <<'EOF'
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    location / {
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

# 6. ComfyUI Install
install_comfyui_core "$PYTHON_310"
install_standard_nodes
setup_systemd

echo "--------------------------------------------------------"
echo "Setup complete! Secured with Nginx Auth."
echo "URL: https://$(curl -s ifconfig.me)"
echo "Username: $AUTH_USER"
echo "--------------------------------------------------------"