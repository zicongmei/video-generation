# ComfyUI on GKE Autopilot (Spot Instances)

This deployment runs ComfyUI with an L4 GPU on GKE Autopilot spot instances.

## Setup and Deployment

1. **Generate Secrets**: Use the provided script to generate both basic authentication and TLS secrets.
   ```bash
   chmod +x generate_secret.sh
   ./generate_secret.sh <username> <password>
   ```

2. **Apply Manifests**:
   ```bash
   kubectl apply -f secret.yaml
   kubectl apply -f tls-secret.yaml
   kubectl apply -f configmap.yaml
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

3. **Access ComfyUI**:
   Once the LoadBalancer is ready and the pod is running:
   - URL: `https://<EXTERNAL-IP>`
   - Credentials: The username and password you used in step 1.
   - **Note**: Since it uses a self-signed certificate, you will need to bypass the browser warning or use `curl -k`.

## Configuration Details
- **Port 80**: Automatically redirects to port 443 (HTTPS).
- **Port 443**: HTTPS with basic authentication proxying to ComfyUI (8188).
- **GPU**: NVIDIA L4 (Spot instance).
- **Memory**: 32Gi.