# video-generation

## Model Management

When a VM is deployed via Terraform (e.g., `gcp/terraform/l4`), ComfyUI is installed automatically, but the heavy machine learning models are **not** downloaded by default to save startup time and bandwidth.

You can manage your models through a dedicated web interface:

1. **Access the Downloader:** Once the VM is running, navigate to `https://<YOUR_VM_IP>/dl`.
2. **Authentication:** Log in using the same Basic Auth credentials configured in your `terraform.tfvars` (e.g., `root` and your `auth_password`).
3. **Download Workflows:** The interface lists supported workflows (like Z-Image-Turbo, LTX-2, Wan 2.2). Click **Download Models** for the workflow you want to use.
   - Downloads run in parallel in the background.
   - If a download is interrupted, you can click **Restart Download** to resume from where it left off.
   - The UI displays the download progress (percentage) for partial files.
4. **Manage Disk Space:** You can delete individual models directly from the UI to free up disk space when switching between workflows.