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

async function get_image_blob(filename, subfolder, type) {
    const query = new URLSearchParams({ filename, subfolder, type }).toString();
    const response = await fetch(get_api_url(`/view?${query}`), {
        headers: get_auth_header()
    });
    return await response.blob();
}

async function get_image(filename, subfolder, type) {
    const blob = await get_image_blob(filename, subfolder, type);
    return URL.createObjectURL(blob);
}

// IndexedDB logic
const DB_NAME = 'ComfyUIHistory';
const DB_VERSION = 1;
const STORE_NAME = 'images';
let db;

function initDB() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);
        request.onupgradeneeded = (e) => {
            db = e.target.result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
            }
        };
        request.onsuccess = (e) => {
            db = e.target.result;
            resolve(db);
        };
        request.onerror = (e) => reject(e);
    });
}

async function saveToHistory(imageBlob, prompt) {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);
    const item = {
        imageBlob,
        prompt,
        timestamp: new Date().getTime()
    };
    return new Promise((resolve, reject) => {
        const request = store.add(item);
        request.onsuccess = () => {
            item.id = request.result;
            addToSidebar(item);
            resolve();
        };
        request.onerror = (e) => reject(e);
    });
}

function addToSidebar(item) {
    const historyList = document.getElementById('history_list');
    const div = document.createElement('div');
    div.className = 'history-item';
    div.dataset.id = item.id;
    
    const img = document.createElement('img');
    img.src = URL.createObjectURL(item.imageBlob);
    img.title = item.prompt;
    img.onclick = () => {
        document.getElementById('prompt').value = item.prompt;
        
        // Show in modal
        const modal = document.getElementById('image_modal');
        const modalImg = document.getElementById('modal_img');
        const captionText = document.getElementById('modal_caption');
        
        modal.style.display = "block";
        modalImg.src = img.src;
        captionText.innerHTML = item.prompt;

        // Also show it in main view
        const image_container = document.getElementById('image-container');
        image_container.innerHTML = '';
        const mainImg = document.createElement('img');
        mainImg.src = img.src;
        mainImg.className = 'generated-image';
        mainImg.style.cursor = 'pointer';
        mainImg.onclick = () => {
            const modal = document.getElementById('image_modal');
            const modalImg = document.getElementById('modal_img');
            const captionText = document.getElementById('modal_caption');
            modal.style.display = "block";
            modalImg.src = mainImg.src;
            captionText.innerHTML = item.prompt;
        };
        image_container.appendChild(mainImg);
    };
    
    const delBtn = document.createElement('button');
    delBtn.className = 'delete-btn';
    delBtn.innerHTML = '×';
    delBtn.onclick = (e) => {
        e.stopPropagation();
        deleteFromHistory(item.id, div);
    };
    
    div.appendChild(img);
    div.appendChild(delBtn);
    historyList.insertBefore(div, historyList.firstChild);
}

async function loadHistory() {
    const transaction = db.transaction([STORE_NAME], 'readonly');
    const store = transaction.objectStore(STORE_NAME);
    const request = store.getAll();
    request.onsuccess = () => {
        const items = request.result;
        items.sort((a, b) => a.timestamp - b.timestamp);
        items.forEach(addToSidebar);
    };
}

async function deleteFromHistory(id, element) {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);
    const request = store.delete(id);
    request.onsuccess = () => {
        element.remove();
    };
}

document.getElementById('clear_history').onclick = () => {
    if (confirm('Clear all history?')) {
        const transaction = db.transaction([STORE_NAME], 'readwrite');
        const store = transaction.objectStore(STORE_NAME);
        store.clear().onsuccess = () => {
            document.getElementById('history_list').innerHTML = '';
        };
    }
};

async function get_history(prompt_id) {
    const response = await fetch(get_api_url(`/history/${prompt_id}`), {
        headers: get_auth_header()
    });
    return await response.json();
}

document.getElementById('toggle_debug').onclick = function() {
    const debug_info = document.getElementById('debug_info');
    if (debug_info.style.display === 'none') {
        debug_info.style.display = 'block';
        this.innerText = 'Hide Debug Info';
    } else {
        debug_info.style.display = 'none';
        this.innerText = 'Show Debug Info';
    }
};

async function generate() {
    const start_time = performance.now();
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
            if (prompt_node.inputs.value !== undefined) prompt_node.inputs.value = prompt_text;
            else if (prompt_node.inputs.string !== undefined) prompt_node.inputs.string = prompt_text;
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

        // Debug: Show Request
        document.getElementById('debug_request').innerText = JSON.stringify(api_workflow, null, 2);

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

                // Debug: Show Response and Time
                const end_time = performance.now();
                document.getElementById('debug_time').innerText = ((end_time - start_time) / 1000).toFixed(2) + ' seconds';
                document.getElementById('debug_response').innerText = JSON.stringify(history[prompt_id], null, 2);

                const outputs = history[prompt_id].outputs;
                
                let images_found = 0;
                for (const node_id in outputs) {
                    if (outputs[node_id].images) {
                        for (const image_data of outputs[node_id].images) {
                            const blob = await get_image_blob(image_data.filename, image_data.subfolder, image_data.type);
                            const img_url = URL.createObjectURL(blob);
                            
                            const img = document.createElement('img');
                            img.src = img_url;
                            img.className = 'generated-image';
                            img.style.maxWidth = '100%';
                            img.style.marginBottom = '10px';
                            img.style.borderRadius = '4px';
                            img.style.cursor = 'pointer';
                            img.onclick = () => {
                                const modal = document.getElementById('image_modal');
                                const modalImg = document.getElementById('modal_img');
                                const captionText = document.getElementById('modal_caption');
                                modal.style.display = "block";
                                modalImg.src = img.src;
                                captionText.innerHTML = prompt_text;
                            };
                            image_container.appendChild(img);
                            
                            // Save to history
                            saveToHistory(blob, prompt_text);
                            
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
window.addEventListener('load', () => {
    load_config();
    initDB().then(loadHistory);

    // Modal close logic
    const modal = document.getElementById('image_modal');
    const closeBtn = document.getElementById('close_modal');
    
    closeBtn.onclick = function() {
        modal.style.display = "none";
    }

    window.onclick = function(event) {
        if (event.target == modal) {
            modal.style.display = "none";
        }
    }
});
