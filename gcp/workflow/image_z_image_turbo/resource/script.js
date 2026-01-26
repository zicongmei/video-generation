let server_address = "";
const client_id = Math.random().toString(36).substring(2, 15);

function get_api_url(path) {
    let host = document.getElementById('server_ip').value.trim();
    if (!host) {
        host = window.location.hostname + (window.location.port ? ':' + window.location.port : '');
    }

    // Default to https if it's port 443 or no port is specified on a remote host
    let protocol = 'http:';
    if (host.includes(':443') || (host.indexOf(':') === -1 && host !== 'localhost' && host !== '127.0.0.1')) {
        protocol = 'https:';
    }
    
    // If we are running on a secure page already, use https
    if (window.location.protocol === 'https:') {
        protocol = 'https:';
    }

    // Clean up host (remove protocol if user accidentally typed it)
    host = host.replace(/^(http|https):\/\//, '');

    return `${protocol}//${host}${path}`;
}

function get_auth_header() {
    const user = document.getElementById('username').value.trim();
    const pass = document.getElementById('password').value.trim();
    if (user && pass) {
        return { 'Authorization': 'Basic ' + btoa(user + ':' + pass) };
    }
    return {};
}

async function queue_prompt(prompt) {
    const response = await fetch(get_api_url('/prompt'), {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            ...get_auth_header()
        },
        body: JSON.stringify({ prompt, client_id })
    });
    return await response.json();
}

async function get_image(filename, subfolder, type) {
    const query = new URLSearchParams({ filename, subfolder, type }).toString();
    const response = await fetch(get_api_url(`/view?${query}`), {
        headers: get_auth_header()
    });
    const blob = await response.blob();
    return URL.createObjectURL(blob);
}

async function get_history(prompt_id) {
    const response = await fetch(get_api_url(`/history/${prompt_id}`), {
        headers: get_auth_header()
    });
    return await response.json();
}

async function generate() {
    const prompt_text = document.getElementById('prompt').value;
    const generate_btn = document.getElementById('generate');
    const status_div = document.getElementById('status');
    const output_img = document.getElementById('output-image');

    generate_btn.disabled = true;
    status_div.innerText = 'Loading workflow...';

    try {
        const response = await fetch('resource/workflow.json');
        let workflow = await response.json();

        // Handle UI format (has .nodes) vs API format (is a dictionary)
        let api_workflow = workflow;
        if (workflow.nodes) {
            status_div.innerText = 'Error: UI format detected. Please export as API Format (Dev mode).';
            throw new Error("ComfyUI UI format detected. This script requires 'API Format' JSON. Enable 'Dev mode' in ComfyUI settings and 'Save (API Format)'.");
        }

        // Find the prompt node (ID 58 or by class_type/title)
        let prompt_node = null;
        if (api_workflow["58"]) {
            prompt_node = api_workflow["58"];
        } else {
            for (const id in api_workflow) {
                const node = api_workflow[id];
                if (node.class_type === "PrimitiveStringMultiline" || node._meta?.title === "Prompt") {
                    prompt_node = node;
                    break;
                }
            }
        }

        if (!prompt_node) throw new Error("Could not find prompt node in workflow.");
        
        // Update the prompt value
        // For PrimitiveStringMultiline, the input is usually 'string' or 'text'
        if (prompt_node.inputs.string !== undefined) prompt_node.inputs.string = prompt_text;
        else if (prompt_node.inputs.text !== undefined) prompt_node.inputs.text = prompt_text;
        else {
            // Fallback: update the first input that is a string
            for (const key in prompt_node.inputs) {
                if (typeof prompt_node.inputs[key] === 'string') {
                    prompt_node.inputs[key] = prompt_text;
                    break;
                }
            }
        }

        status_div.innerText = 'Queueing prompt...';
        const queued = await queue_prompt(api_workflow);
        const prompt_id = queued.prompt_id;

        status_div.innerText = 'Waiting for generation...';
        
        // Polling for completion (simpler than WebSocket for a basic example)
        let completed = false;
        while (!completed) {
            const history = await get_history(prompt_id);
            if (history[prompt_id]) {
                completed = true;
                const outputs = history[prompt_id].outputs;
                // Look for SaveImage output (ID 9 or 60)
                let image_data = null;
                for (const node_id in outputs) {
                    if (outputs[node_id].images) {
                        image_data = outputs[node_id].images[0];
                        break;
                    }
                }

                if (image_data) {
                    const img_url = await get_image(image_data.filename, image_data.subfolder, image_data.type);
                    output_img.src = img_url;
                    output_img.style.display = 'block';
                    status_div.innerText = 'Done!';
                } else {
                    status_div.innerText = 'Generation failed: No image output found.';
                }
            } else {
                await new Promise(r => setTimeout(r, 1000));
            }
        }
    } catch (error) {
        console.error(error);
        status_div.innerText = 'Error: ' + error.message;
    } finally {
        generate_btn.disabled = false;
    }
}

document.getElementById('generate').addEventListener('click', generate);
