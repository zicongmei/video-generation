#!/bin/bash
set -e

# Load common library
source $(dirname "$0")/swarmui_common_lib.sh

setup_serial_logging

echo "Starting setup (Authenticated) for SwarmUI..."

# 1. Fetch credentials from metadata
echo "Fetching credentials from metadata..."
AUTH_USER=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_username || echo "root")
AUTH_PASS=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/auth_password || echo "qps564")

# 2. Dependencies and cleanup
install_system_dependencies

echo "Stopping ComfyUI service if running..."
sudo systemctl stop comfyui || true
sudo systemctl disable comfyui || true

echo "Cleaning up conflicting Nginx configurations..."
sudo rm -f /etc/nginx/sites-enabled/comfyui
sudo rm -f /etc/nginx/sites-enabled/default

echo "Cleaning up existing services on port 443..."
sudo systemctl stop swarmui-proxy || true
sudo fuser -k 443/tcp || true
sudo dpkg --configure -a || true
sudo apt-get install -f -y || true

# 3. Environment and SSL
PYTHON_310=$(find_python310)
# Create a local bin directory to override python3 for SwarmUI's internal installers
mkdir -p $HOME/.local/bin
ln -sf $PYTHON_310 $HOME/.local/bin/python3
export PATH="$HOME/.local/bin:$PATH"

setup_ssl_cert

# 4. Auth File
echo "Creating authentication file for user: $AUTH_USER"
sudo htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS"

# 5. Nginx Configuration
sudo tee /etc/nginx/sites-available/swarmui <<'EOF'
server {
    listen 443 ssl;
    server_name _;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # Increase max body size for large model uploads if needed
    client_max_body_size 0;

    location / {
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://127.0.0.1:7801;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # SwarmUI specific: some long running requests might need longer timeouts
        proxy_read_timeout 600s;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/swarmui /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# 6. SwarmUI Install
install_swarmui

# Force cleanup of existing venvs to ensure they are recreated with Python 3.10
echo "Cleaning up any existing broken backend environments..."
sudo rm -rf $HOME/SwarmUI/dlbackend/ComfyUI/venv || true

# 7. Systemd Setup
# Update the service to also use the python 3.10 PATH
sudo tee /etc/systemd/system/swarmui.service <<EOF
[Unit]
Description=SwarmUI Backend
After=network.target nginx.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/SwarmUI
Environment="PATH=$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$HOME/SwarmUI/launch-linux.sh --launch_mode none --host 127.0.0.1 --port 7801
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable swarmui
sudo systemctl restart swarmui

echo "--------------------------------------------------------"
echo "Setup complete! Secured with Nginx Auth."
echo "URL: https://$(curl -s ifconfig.me)"
echo "Username: $AUTH_USER"
echo "--------------------------------------------------------"
