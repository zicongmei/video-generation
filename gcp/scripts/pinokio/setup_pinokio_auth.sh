#!/bin/bash
set -e

# Load common library
source $(dirname "$0")/pinokio_common_lib.sh

setup_serial_logging

echo "Starting setup (Authenticated) for Pinokio..."

# 1. Fetch credentials from metadata
echo "Fetching credentials from metadata..."
AUTH_USER=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_username)
AUTH_PASS=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_password)

# 2. Dependencies and cleanup
install_system_dependencies 

echo "Cleaning up Pinokio GUI if present..."
sudo apt-get remove -y pinokio || true

echo "Cleaning up conflicting Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/*

echo "Cleaning up existing services on port 443..."
sudo fuser -k 443/tcp || true
sudo dpkg --configure -a || true
sudo apt-get install -f -y || true

# 3. SSL Cert
setup_ssl_cert

# 4. Auth File
echo "Creating authentication file for user: $AUTH_USER"
sudo htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"

# 5. Nginx Configuration
sudo tee /etc/nginx/sites-available/pinokio <<'EOF'
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    client_max_body_size 0;

    location / {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:42000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_read_timeout 600s;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/pinokio /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# 6. Pinokio Install
install_pinokio

# 7. Systemd Setup
setup_systemd

echo "--------------------------------------------------------"
echo "Setup complete! Secured with Nginx Auth."
echo "URL: https://$(curl -s ifconfig.me)"
echo "Username: $AUTH_USER"
echo "--------------------------------------------------------"
