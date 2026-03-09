import os
import subprocess
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI()

# Workflow to representative file mapping
WORKFLOWS = {
    "z_image_turbo": {
        "name": "Z-Image-Turbo",
        "script": "/root/models_download/z_image_turbo.sh",
    },
    "ltx2_t2v": {
        "name": "LTX-2 T2V",
        "script": "/root/models_download/ltx2_t2v.sh",
    },
    "video_wan2_2_14B_t2v": {
        "name": "Wan 2.2 T2V (14B)",
        "script": "/root/models_download/video_wan2_2_14B_t2v.sh",
    },
    "video_wan2_2_14B_i2v": {
        "name": "Wan 2.2 I2V (14B)",
        "script": "/root/models_download/video_wan2_2_14B_i2v.sh",
    }
}

def check_models(workflow_id):
    script_path = WORKFLOWS[workflow_id]["script"]
    if not os.path.exists(script_path):
        return False
    
    try:
        # Get list of models from the script itself
        result = subprocess.check_output(["/bin/bash", script_path, "--list"], text=True)
        model_paths = result.strip().split("\n")
        for model_path in model_paths:
            if model_path and not os.path.exists(model_path):
                return False
        return True
    except Exception as e:
        print(f"Error checking models for {workflow_id}: {e}")
        return False

@app.get("/download/api/status")
async def get_status():
    status = {}
    for wf_id in WORKFLOWS:
        status[wf_id] = {
            "name": WORKFLOWS[wf_id]["name"],
            "exists": check_models(wf_id)
        }
    return JSONResponse(content=status)

@app.post("/download/api/trigger/{workflow_id}")
async def trigger_download(workflow_id: str):
    if workflow_id not in WORKFLOWS:
        return JSONResponse(content={"error": "Invalid workflow ID"}, status_code=400)
    
    script_path = WORKFLOWS[workflow_id]["script"]
    if not os.path.exists(script_path):
        return JSONResponse(content={"error": f"Script {script_path} not found"}, status_code=500)
    
    # Run in background to avoid blocking
    subprocess.Popen(["/bin/bash", script_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return JSONResponse(content={"message": f"Started download for {WORKFLOWS[workflow_id]['name']}"})

@app.get("/download", response_class=HTMLResponse)
async def get_index():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Model Downloader</title>
        <style>
            body { font-family: sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.6; }
            .card { border: 1px solid #ddd; padding: 20px; margin-bottom: 20px; border-radius: 8px; display: flex; justify-content: space-between; align-items: center; }
            .status { font-weight: bold; }
            .exists { color: green; }
            .missing { color: red; }
            button { padding: 10px 20px; cursor: pointer; background: #007bff; color: white; border: none; border-radius: 4px; }
            button:disabled { background: #ccc; cursor: not-allowed; }
            .refresh { margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <h1>Model Downloader</h1>
        <p>Manage ComfyUI models for different workflows.</p>
        <button class="refresh" onclick="updateStatus()">Refresh Status</button>
        <div id="workflows"></div>

        <script>
            async function updateStatus() {
                const response = await fetch('/download/api/status');
                const status = await response.json();
                const container = document.getElementById('workflows');
                container.innerHTML = '';
                
                for (const id in status) {
                    const wf = status[id];
                    const div = document.createElement('div');
                    div.className = 'card';
                    div.innerHTML = `
                        <div>
                            <h3>${wf.name}</h3>
                            <p class="status ${wf.exists ? 'exists' : 'missing'}">
                                ${wf.exists ? '● Installed' : '○ Missing'}
                            </p>
                        </div>
                        <button onclick="triggerDownload('${id}')" ${wf.exists ? 'disabled' : ''}>
                            ${wf.exists ? 'Installed' : 'Download Models'}
                        </button>
                    `;
                    container.appendChild(div);
                }
            }

            async function triggerDownload(id) {
                const btn = event.target;
                btn.disabled = true;
                btn.innerText = 'Starting...';
                const response = await fetch(`/download/api/trigger/${id}`, { method: 'POST' });
                const result = await response.json();
                alert(result.message || result.error);
                setTimeout(updateStatus, 2000);
            }

            updateStatus();
            // Poll every 30 seconds
            setInterval(updateStatus, 30000);
        </script>
    </body>
    </html>
    """

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
