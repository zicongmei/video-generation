import os
import subprocess
import json
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

def get_model_status(workflow_id):
    script_path = WORKFLOWS[workflow_id]["script"]
    if not os.path.exists(script_path):
        return []
    
    models_status = []
    try:
        # Get list of models as JSON from the script itself
        result = subprocess.check_output(["/bin/bash", script_path, "--list"], text=True)
        model_data = json.loads(result.strip())
        for item in model_data:
            model_path = item.get("path")
            if model_path:
                models_status.append({
                    "path": model_path,
                    "filename": os.path.basename(model_path),
                    "url": item.get("url", ""),
                    "exists": os.path.exists(model_path)
                })
        return models_status
    except Exception as e:
        print(f"Error checking models for {workflow_id}: {e}")
        return []

def is_downloading(workflow_id):
    script_path = WORKFLOWS[workflow_id]["script"]
    try:
        # pgrep -f matches the full command line. 
        # We look for the script path specifically.
        subprocess.check_call(["pgrep", "-f", script_path])
        return True
    except subprocess.CalledProcessError:
        return False

@app.get("/download/api/status")
async def get_status():
    status = {}
    for wf_id in WORKFLOWS:
        models = get_model_status(wf_id)
        exists = len(models) > 0 and all(m["exists"] for m in models)
        downloading = False
        if not exists:
            downloading = is_downloading(wf_id)
            
        status[wf_id] = {
            "name": WORKFLOWS[wf_id]["name"],
            "exists": exists,
            "downloading": downloading,
            "models": models
        }
    return JSONResponse(content=status)

@app.post("/download/api/trigger/{workflow_id}")
async def trigger_download(workflow_id: str):
    if workflow_id not in WORKFLOWS:
        return JSONResponse(content={"error": "Invalid workflow ID"}, status_code=400)
    
    if is_downloading(workflow_id):
        return JSONResponse(content={"message": "Download already in progress"})

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
            body { font-family: sans-serif; max-width: 900px; margin: 40px auto; padding: 20px; line-height: 1.6; }
            .card { border: 1px solid #ddd; padding: 20px; margin-bottom: 20px; border-radius: 8px; }
            .card-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #eee; padding-bottom: 10px; margin-bottom: 10px; }
            .card-header h3 { margin: 0; }
            .status { font-weight: bold; margin: 0; }
            .exists { color: green; }
            .missing { color: red; }
            .downloading { color: orange; }
            button { padding: 10px 20px; cursor: pointer; background: #007bff; color: white; border: none; border-radius: 4px; }
            button:disabled { background: #ccc; cursor: not-allowed; }
            .refresh { margin-bottom: 20px; }
            .model-list { margin: 10px 0 0 0; padding-left: 20px; list-style-type: none; font-size: 0.9em; }
            .model-list li { margin-bottom: 5px; word-break: break-all; }
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
                    
                    let statusText = '○ Missing';
                    let statusClass = 'missing';
                    let btnText = 'Download Models';
                    let btnDisabled = false;

                    if (wf.exists) {
                        statusText = '● Installed';
                        statusClass = 'exists';
                        btnText = 'Installed';
                        btnDisabled = true;
                    } else if (wf.downloading) {
                        statusText = '⏳ Downloading...';
                        statusClass = 'downloading';
                        btnText = 'Downloading...';
                        btnDisabled = true;
                    }

                    let modelsHtml = '<ul class="model-list">';
                    if (wf.models && wf.models.length > 0) {
                        wf.models.forEach(m => {
                            const icon = m.exists ? '<span class="exists">✔</span>' : '<span class="missing">✖</span>';
                            modelsHtml += `<li>${icon} ${m.filename}</li>`;
                        });
                    } else {
                        modelsHtml += '<li>No models found or script missing.</li>';
                    }
                    modelsHtml += '</ul>';

                    div.innerHTML = `
                        <div class="card-header">
                            <div>
                                <h3>${wf.name}</h3>
                                <p class="status ${statusClass}">${statusText}</p>
                            </div>
                            <button onclick="triggerDownload('${id}')" ${btnDisabled ? 'disabled' : ''}>
                                ${btnText}
                            </button>
                        </div>
                        ${modelsHtml}
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
                console.log(result.message || result.error);
                setTimeout(updateStatus, 1000);
            }

            updateStatus();
            // Poll every 5 seconds for more responsive UI during download
            setInterval(updateStatus, 5000);
        </script>
    </body>
    </html>
    """

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
