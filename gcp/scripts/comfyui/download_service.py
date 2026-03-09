import os
import subprocess
import json
import asyncio
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse

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

active_tasks = {}
active_processes = {}

async def download_workflow_models(workflow_id, models_data):
    procs = []
    try:
        for m in models_data:
            os.makedirs(os.path.dirname(m['path']), exist_ok=True)
            # Use wget -c to continue from where it left off
            p = await asyncio.create_subprocess_exec(
                "wget", "-c", "-O", m['path'], m['url'],
                stdout=asyncio.subprocess.DEVNULL,
                stderr=asyncio.subprocess.DEVNULL
            )
            procs.append(p)
        
        active_processes[workflow_id] = procs
        
        # Wait for all parallel downloads to complete
        await asyncio.gather(*(p.wait() for p in procs))
    except asyncio.CancelledError:
        # If task is cancelled, explicitly kill running wget processes
        for p in procs:
            try:
                p.kill()
            except Exception:
                pass
        raise
    finally:
        if workflow_id in active_processes:
            del active_processes[workflow_id]
        if workflow_id in active_tasks:
            del active_tasks[workflow_id]

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

@app.get("/download/api/status")
async def get_status():
    status = {}
    for wf_id in WORKFLOWS:
        models = get_model_status(wf_id)
        exists = len(models) > 0 and all(m["exists"] for m in models)
        downloading = wf_id in active_tasks
            
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
    
    # If currently downloading, cancel the old task so we can restart
    if workflow_id in active_tasks:
        active_tasks[workflow_id].cancel()
        await asyncio.sleep(0.2) # Allow propagation of cancellation to kill processes
        
    models = get_model_status(workflow_id)
    if not models:
        return JSONResponse(content={"error": f"No models found for {workflow_id}"}, status_code=500)
    
    # Start new download task
    task = asyncio.create_task(download_workflow_models(workflow_id, models))
    active_tasks[workflow_id] = task
    
    return JSONResponse(content={"message": f"Started download for {WORKFLOWS[workflow_id]['name']}"})

@app.post("/download/api/stop/{workflow_id}")
async def stop_download(workflow_id: str):
    if workflow_id in active_tasks:
        active_tasks[workflow_id].cancel()
        return JSONResponse(content={"message": f"Stopped download for {WORKFLOWS[workflow_id]['name']}"})
    return JSONResponse(content={"message": "No active download to stop"})

@app.post("/download/api/remove")
async def remove_model(request: Request):
    data = await request.json()
    path = data.get("path")
    if path and path.startswith("/root/ComfyUI/models/") and os.path.exists(path):
        try:
            os.remove(path)
            return JSONResponse(content={"message": f"Removed {os.path.basename(path)}"})
        except Exception as e:
            return JSONResponse(content={"error": str(e)}, status_code=500)
    return JSONResponse(content={"error": "Invalid or missing path"}, status_code=400)

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
            button { padding: 10px 20px; cursor: pointer; background: #007bff; color: white; border: none; border-radius: 4px; border: 1px solid #007bff; transition: background 0.2s; }
            button:hover { background: #0056b3; }
            button:disabled { background: #ccc; border-color: #ccc; cursor: not-allowed; }
            .stop-btn { background: #ffc107; color: black; border-color: #ffc107; margin-left: 10px; }
            .stop-btn:hover { background: #e0a800; }
            .delete-btn { background: #dc3545; padding: 4px 8px; font-size: 0.8em; margin-left: 10px; border-color: #dc3545; }
            .delete-btn:hover { background: #c82333; }
            .refresh { margin-bottom: 20px; }
            .model-list { margin: 10px 0 0 0; padding-left: 20px; list-style-type: none; font-size: 0.9em; }
            .model-list li { margin-bottom: 8px; word-break: break-all; display: flex; align-items: center; }
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
                    let showStop = false;

                    if (wf.exists) {
                        statusText = '● Installed';
                        statusClass = 'exists';
                        btnText = 'Installed';
                        btnDisabled = true;
                    } else if (wf.downloading) {
                        statusText = '⏳ Downloading...';
                        statusClass = 'downloading';
                        btnText = 'Restart Download';
                        showStop = true;
                    }

                    let modelsHtml = '<ul class="model-list">';
                    if (wf.models && wf.models.length > 0) {
                        wf.models.forEach(m => {
                            const icon = m.exists ? '<span class="exists">✔</span>' : '<span class="missing">✖</span>';
                            const delBtn = m.exists ? `<button class="delete-btn" onclick="removeModel('${m.path}')">Delete</button>` : '';
                            modelsHtml += `<li>${icon}&nbsp;${m.filename} ${delBtn}</li>`;
                        });
                    } else {
                        modelsHtml += '<li>No models found or script missing.</li>';
                    }
                    modelsHtml += '</ul>';

                    const stopBtnHtml = showStop ? `<button class="stop-btn" onclick="stopDownload('${id}')">Stop Download</button>` : '';

                    div.innerHTML = `
                        <div class="card-header">
                            <div>
                                <h3>${wf.name}</h3>
                                <p class="status ${statusClass}">${statusText}</p>
                            </div>
                            <div>
                                <button onclick="triggerDownload('${id}', this)" ${btnDisabled ? 'disabled' : ''}>
                                    ${btnText}
                                </button>
                                ${stopBtnHtml}
                            </div>
                        </div>
                        ${modelsHtml}
                    `;
                    container.appendChild(div);
                }
            }

            async function triggerDownload(id, btn) {
                btn.disabled = true;
                btn.innerText = 'Starting...';
                const response = await fetch(`/download/api/trigger/${id}`, { method: 'POST' });
                const result = await response.json();
                console.log(result.message || result.error);
                setTimeout(updateStatus, 500);
            }

            async function stopDownload(id) {
                const response = await fetch(`/download/api/stop/${id}`, { method: 'POST' });
                const result = await response.json();
                console.log(result.message || result.error);
                setTimeout(updateStatus, 500);
            }
            
            async function removeModel(path) {
                if(!confirm("Are you sure you want to delete this model?")) return;
                const response = await fetch('/download/api/remove', { 
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ path: path })
                });
                const result = await response.json();
                console.log(result.message || result.error);
                setTimeout(updateStatus, 500);
            }

            updateStatus();
            setInterval(updateStatus, 5000);
        </script>
    </body>
    </html>
    """

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
