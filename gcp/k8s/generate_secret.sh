#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

USERNAME=$1
PASSWORD=$2

# Function to generate htpasswd content
generate_htpasswd() {
    if command -v htpasswd &> /dev/null; then
        htpasswd -nb "$1" "$2"
    else
        # Fallback using openssl (MD5 crypt)
        local hash=$(openssl passwd -apr1 "$2")
        echo "$1:$hash"
    fi
}

echo "Generating Basic Auth secret (secret.yaml)..."
HTPASSWD_CONTENT=$(generate_htpasswd "$USERNAME" "$PASSWORD")
# Ensure there is a newline at the end of the htpasswd content as nginx sometimes requires it
B64_HTPASSWD=$(printf "%s\n" "$HTPASSWD_CONTENT" | base64 | tr -d '\n')

cat <<EOF > secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-auth
type: Opaque
data:
  htpasswd: $B64_HTPASSWD
EOF

echo "Generating Self-Signed TLS certificate and secret (tls-secret.yaml)..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=comfyui.local/O=ComfyUI" 2>/dev/null

kubectl create secret tls nginx-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml > tls-secret.yaml

# Clean up temp files
rm tls.key tls.crt

echo "Done!"
echo "- secret.yaml generated"
echo "- tls-secret.yaml generated"