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
    const width = parseInt(document.getElementById('width').value);
    const height = parseInt(document.getElementById('height').value);
    const batch_size = parseInt(document.getElementById('batch_size').value);
    let seed = parseInt(document.getElementById('seed').value);
    
    if (seed === -1) {
        seed = Math.floor(Math.random() * 1000000000000000);
    }

    const generate_btn = document.getElementById('generate');
    const status_div = document.getElementById('status');
    const image_container = document.getElementById('image-container');

    generate_btn.disabled = true;
    status_div.innerText = 'Loading workflow...';
    image_container.innerHTML = ''; // Clear previous images

    try {
        const response = await fetch('resource/workflow.json');
        let api_workflow = await response.json();

        // Find and update nodes
        let prompt_node = null;
        let size_node = null;
        let sampler_node = null;

        for (const id in api_workflow) {
            const node = api_workflow[id];
            if (node.class_type === "PrimitiveStringMultiline" || node._meta?.title === "Prompt") {
                prompt_node = node;
            }
            if (node.class_type === "EmptySD3LatentImage" || node.class_type === "EmptyLatentImage") {
                size_node = node;
            }
            if (node.class_type === "KSampler" || node.class_type === "KSamplerAdvanced") {
                sampler_node = node;
            }
        }

        // Update Prompt
        if (prompt_node) {
            if (prompt_node.inputs.string !== undefined) prompt_node.inputs.string = prompt_text;
            else if (prompt_node.inputs.text !== undefined) prompt_node.inputs.text = prompt_text;
        }

        // Update Size
        if (size_node) {
            size_node.inputs.width = width;
            size_node.inputs.height = height;
            size_node.inputs.batch_size = batch_size;
        }

        // Update Seed
        if (sampler_node) {
            sampler_node.inputs.seed = seed;
            if (sampler_node.inputs.noise_seed !== undefined) sampler_node.inputs.noise_seed = seed;
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
                
                let images_found = 0;
                for (const node_id in outputs) {
                    if (outputs[node_id].images) {
                        for (const image_data of outputs[node_id].images) {
                            const img_url = await get_image(image_data.filename, image_data.subfolder, image_data.type);
                            const img = document.createElement('img');
                            img.src = img_url;
                            img.className = 'generated-image';
                            img.style.maxWidth = '100%';
                            img.style.marginBottom = '10px';
                            img.style.borderRadius = '4px';
                            image_container.appendChild(img);
                            images_found++;
                        }
                    }
                }

                if (images_found > 0) {
                    status_div.innerText = `Done! Generated ${images_found} images.`;
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

document.getElementById('toggle_password').addEventListener('click', function() {
    const pass_input = document.getElementById('password');
    if (pass_input.type === 'password') {
        pass_input.type = 'text';
        this.innerText = 'Hide';
    } else {
        pass_input.type = 'password';
        this.innerText = 'Show';
    }
});

// Persistence Logic
function save_config() {
    const config = {
        server_ip: document.getElementById('server_ip').value,
        username: document.getElementById('username').value,
        password: document.getElementById('password').value,
        width: document.getElementById('width').value,
        height: document.getElementById('height').value,
        batch_size: document.getElementById('batch_size').value,
        seed: document.getElementById('seed').value,
        prompt: document.getElementById('prompt').value
    };
    localStorage.setItem('comfy_config', JSON.stringify(config));
}

function load_config() {
    const saved = localStorage.getItem('comfy_config');
    if (saved) {
        const config = JSON.parse(saved);
        if (config.server_ip) document.getElementById('server_ip').value = config.server_ip;
        if (config.username) document.getElementById('username').value = config.username;
        if (config.password) document.getElementById('password').value = config.password;
        if (config.width) document.getElementById('width').value = config.width;
        if (config.height) document.getElementById('height').value = config.height;
        if (config.batch_size) document.getElementById('batch_size').value = config.batch_size;
        if (config.seed) document.getElementById('seed').value = config.seed;
        if (config.prompt) document.getElementById('prompt').value = config.prompt;
    }
}

// Add event listeners to save on change
['server_ip', 'username', 'password', 'width', 'height', 'batch_size', 'seed', 'prompt'].forEach(id => {
    document.getElementById(id).addEventListener('input', save_config);
});

// Load on startup
window.addEventListener('load', load_config);
