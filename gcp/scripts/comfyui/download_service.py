import os
import subprocess
import json
import asyncio
import urllib.request
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse

app = FastAPI()

# Workflow to representative file mapping
WORKFLOWS = {
    "z_image": {
        "name": "Z-Image",
        "script": "/root/models_download/z_image.sh",
        "category": "Image Models"
    },
    "z_image_turbo": {
        "name": "Z-Image-Turbo",
        "script": "/root/models_download/z_image_turbo.sh",
        "category": "Image Models"
    },
    "longcat": {
        "name": "Longcat",
        "script": "/root/models_download/longcat.sh",
        "category": "Image Models"
    },
    "ltx2_t2v": {
        "name": "LTX-2 T2V",
        "script": "/root/models_download/ltx2_t2v.sh",
        "category": "Video Models"
    },
    "lxt_2_3_i2v": {
        "name": "LTX-2.3 I2V",
        "script": "/root/models_download/lxt_2_3_i2v.sh",
        "category": "Video Models"
    },
    "lxtv_i2v": {
        "name": "LTX-Video I2V",
        "script": "/root/models_download/lxtv_i2v.sh",
        "category": "Video Models"
    },
    "video_wan2_2_14B_t2v": {
        "name": "Wan 2.2 T2V (14B)",
        "script": "/root/models_download/video_wan2_2_14B_t2v.sh",
        "category": "Video Models"
    },
    "video_wan2_2_14B_i2v": {
        "name": "Wan 2.2 I2V (14B)",
        "script": "/root/models_download/video_wan2_2_14B_i2v.sh",
        "category": "Video Models"
    },
    "qwen_image_2512_t2i": {
        "name": "Qwen-Image-2512 T2I",
        "script": "/root/models_download/qwen_image_2512_t2i.sh",
        "category": "Image Models"
    },
    "qwen_3_text": {
        "name": "Qwen-3 Text",
        "script": "/root/models_download/qwen_3_text.sh",
        "category": "Image Models"
    },
    "flux2_dev": {
        "name": "Flux 2 Dev",
        "script": "/root/models_download/flux2_dev.sh",
        "category": "Image Models"
    },
    "krea_2": {
        "name": "Krea-2",
        "script": "/root/models_download/krea_2.sh",
        "category": "Image Models"
    },
    "image_subgraph": {
        "name": "Z-Image-Turbo (Int8/Subgraph)",
        "script": "/root/models_download/image_subgraph.sh",
        "category": "Image Models"
    },
    "image_ideogram_4": {
        "name": "Ideogram-4",
        "script": "/root/models_download/image_ideogram_4.sh",
        "category": "Image Models"
    }
}

active_tasks = {}
active_processes = {}
MODEL_SIZES_CACHE = {}

def fetch_remote_size(url):
    try:
        req = urllib.request.Request(url, method='HEAD')
        with urllib.request.urlopen(req, timeout=10) as response:
            return int(response.headers.get('Content-Length', 0))
    except Exception as e:
        print(f"Error fetching size for {url}: {e}")
    return 0

async def process_model(item):
    model_path = item.get("path")
    url = item.get("url")
    if not model_path or not url:
        return None
    
    if url not in MODEL_SIZES_CACHE:
        size = await asyncio.to_thread(fetch_remote_size, url)
        MODEL_SIZES_CACHE[url] = size
        
    expected_size = MODEL_SIZES_CACHE[url]
    disk_size = os.path.getsize(model_path) if os.path.exists(model_path) else 0
    
    is_full = False
    is_partial = False
    percentage = 0
    
    if expected_size > 0:
        if disk_size >= expected_size:
            is_full = True
            percentage = 100
        elif disk_size > 0:
            is_partial = True
            percentage = round((disk_size / expected_size) * 100, 1)
    else:
        # Fallback if we couldn't fetch the size
        is_full = disk_size > 0
        percentage = 100 if is_full else 0

    return {
        "path": model_path,
        "filename": os.path.basename(model_path),
        "url": url,
        "exists": is_full,
        "partial": is_partial,
        "percentage": percentage,
        "size_gb": round(expected_size / (1024 ** 3), 2) if expected_size > 0 else 0
    }

async def get_model_status(workflow_id):
    script_path = WORKFLOWS[workflow_id]["script"]
    if not os.path.exists(script_path):
        return []
    
    try:
        result = await asyncio.to_thread(subprocess.check_output, ["/bin/bash", script_path, "--list"], text=True)
        model_data = json.loads(result.strip())
        
        tasks = [process_model(item) for item in model_data]
        models_status = await asyncio.gather(*tasks)
        return [m for m in models_status if m is not None]
    except Exception as e:
        print(f"Error checking models for {workflow_id}: {e}")
        return []

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

@app.get("/download/api/status")
async def get_status():
    status = {}
    for wf_id in WORKFLOWS:
        models = await get_model_status(wf_id)
        # It's only fully installed if all models exist fully (not partial)
        exists = len(models) > 0 and all(m["exists"] and not m["partial"] for m in models)
        downloading = wf_id in active_tasks
            
        status[wf_id] = {
            "name": WORKFLOWS[wf_id]["name"],
            "category": WORKFLOWS[wf_id]["category"],
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
        
    models = await get_model_status(workflow_id)
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

@app.post("/download/api/restart_comfyui")
async def restart_comfyui():
    try:
        # Run systemctl restart in a background task to avoid blocking the response
        subprocess.Popen(["sudo", "systemctl", "restart", "comfyui"])
        return JSONResponse(content={"message": "ComfyUI restart initiated"})
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/download/api/restart_vm")
async def restart_vm():
    try:
        # Schedule a reboot in 1 second to allow the response to be sent
        subprocess.Popen(["sudo", "shutdown", "-r", "+1", "VM restart requested via Model Downloader"])
        return JSONResponse(content={"message": "VM restart scheduled in 1 minute. Connection will be lost."})
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/download", response_class=HTMLResponse)
async def get_index():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Model Downloader</title>
        <style>
            body { font-family: sans-serif; max-width: 900px; margin: 40px auto; padding: 20px; line-height: 1.6; }
            .header-actions { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
            .category-header { background: #f8f9fa; padding: 10px 15px; margin: 30px 0 15px 0; border-radius: 6px; border-left: 5px solid #007bff; font-size: 1.4em; font-weight: bold; color: #333; }
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
            .restart-btn { background: #28a745; border-color: #28a745; margin-left: 10px; }
            .restart-btn:hover { background: #218838; }
            .reboot-btn { background: #dc3545; border-color: #dc3545; margin-left: 10px; }
            .reboot-btn:hover { background: #c82333; }
            .delete-btn { background: #dc3545; padding: 4px 8px; font-size: 0.8em; margin-left: 10px; border-color: #dc3545; }
            .delete-btn:hover { background: #c82333; }
            .refresh { margin-right: 10px; }
            .model-list { margin: 10px 0 0 0; padding-left: 20px; list-style-type: none; font-size: 0.9em; }
            .model-list li { margin-bottom: 8px; word-break: break-all; display: flex; align-items: center; }
        </style>
    </head>
    <body>
        <h1>Model Downloader</h1>
        <p>Manage ComfyUI models for different workflows.</p>
        
        <div class="header-actions">
            <div>
                <button class="refresh" onclick="updateStatus()">Refresh Status</button>
            </div>
            <div>
                <button class="restart-btn" onclick="restartComfyUI(this)">Restart ComfyUI</button>
                <button class="reboot-btn" onclick="restartVM(this)">Restart VM</button>
            </div>
        </div>

        <div id="workflows"></div>

        <script>
            async function restartVM(btn) {
                if(!confirm("Are you sure you want to RESTART the entire VM? This will take about a minute.")) return;
                btn.disabled = true;
                btn.innerText = 'Restarting...';
                try {
                    const response = await fetch('/download/api/restart_vm', { method: 'POST' });
                    const result = await response.json();
                    alert(result.message || result.error);
                } catch (e) {
                    alert("Error: " + e);
                }
            }
            async function restartComfyUI(btn) {
                if(!confirm("Are you sure you want to restart ComfyUI?")) return;
                btn.disabled = true;
                btn.innerText = 'Restarting...';
                try {
                    const response = await fetch('/download/api/restart_comfyui', { method: 'POST' });
                    const result = await response.json();
                    alert(result.message || result.error);
                } catch (e) {
                    alert("Error: " + e);
                } finally {
                    btn.disabled = false;
                    btn.innerText = 'Restart ComfyUI';
                }
            }
            async function updateStatus() {
                const response = await fetch('/download/api/status');
                const status = await response.json();
                const container = document.getElementById('workflows');
                container.innerHTML = '';
                
                // Group by category
                const groups = {};
                for (const id in status) {
                    const wf = status[id];
                    const cat = wf.category || "Other Models";
                    if (!groups[cat]) groups[cat] = [];
                    groups[cat].push({ id, ...wf });
                }

                // Desired order
                const categories = ["Image Models", "Video Models"];
                
                categories.forEach(cat => {
                    if (!groups[cat]) return;
                    
                    const groupHeader = document.createElement('div');
                    groupHeader.className = 'category-header';
                    groupHeader.innerText = cat;
                    container.appendChild(groupHeader);
                    
                    groups[cat].forEach(wf => {
                        const id = wf.id;
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
                            btnText = 'Downloading...';
                            btnDisabled = true;
                            showStop = true;
                        }

                        let modelsHtml = '<ul class="model-list">';
                        if (wf.models && wf.models.length > 0) {
                            wf.models.forEach(m => {
                                let icon = '';
                                let textSuffix = '';
                                if (m.exists && !m.partial) {
                                    icon = '<span class="exists">✔</span>';
                                } else if (m.partial) {
                                    icon = '<span class="downloading">⏳</span>';
                                    textSuffix = ` <span style="color:orange;font-size:0.85em;">(${m.percentage}%)</span>`;
                                } else {
                                    icon = '<span class="missing">✖</span>';
                                }
                                
                                // Allow deletion if fully or partially downloaded
                                const delBtn = (m.exists || m.partial) ? `<button class="delete-btn" onclick="removeModel('${m.path}')">Delete</button>` : '';
                                const sizeText = m.size_gb > 0 ? ` <span style="color:#666;font-size:0.85em;">(${m.size_gb} GB)</span>` : '';
                                modelsHtml += `<li>${icon}&nbsp;${m.filename}${sizeText}${textSuffix} ${delBtn}</li>`;
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
                    });
                });
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
