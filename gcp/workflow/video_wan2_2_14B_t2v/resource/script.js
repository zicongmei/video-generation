let server_address = "";
const client_id = Math.random().toString(36).substring(2, 15);

function get_api_url(path) {
    let host = document.getElementById('server_ip').value.trim();
    if (!host) {
        host = window.location.hostname + (window.location.port ? ':' + window.location.port : '');
    }

    let protocol = 'http:';
    if (host.includes(':443') || (host.indexOf(':') === -1 && host !== 'localhost' && host !== '127.0.0.1')) {
        protocol = 'https:';
    }
    
    if (window.location.protocol === 'https:') {
        protocol = 'https:';
    }

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

async function get_file_blob(filename, subfolder, type) {
    const query = new URLSearchParams({ filename, subfolder, type }).toString();
    const response = await fetch(get_api_url(`/view?${query}`), {
        headers: get_auth_header()
    });
    return await response.blob();
}

async function get_history(prompt_id) {
    const response = await fetch(get_api_url(`/history/${prompt_id}`), {
        headers: get_auth_header()
    });
    return await response.json();
}

// IndexedDB logic
const DB_NAME = 'Wan22History';
const DB_VERSION = 1;
const STORE_NAME = 'videos';
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

async function saveToHistory(blob, prompt, type) {
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);
    const item = {
        blob,
        prompt,
        type,
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
    
    const media = document.createElement(item.type === 'video' ? 'video' : 'img');
    media.src = URL.createObjectURL(item.blob);
    media.title = item.prompt;
    if (item.type === 'video') {
        media.loop = true;
        media.muted = true;
        media.onmouseover = () => media.play();
        media.onmouseout = () => media.pause();
    }
    
    media.onclick = () => {
        document.getElementById('prompt').value = item.prompt;
        const video_container = document.getElementById('video-container');
        video_container.innerHTML = '';
        const mainMedia = document.createElement(item.type === 'video' ? 'video' : 'img');
        mainMedia.src = media.src;
        mainMedia.className = 'generated-video';
        if (item.type === 'video') {
            mainMedia.controls = true;
            mainMedia.autoplay = true;
            mainMedia.loop = true;
        }
        video_container.appendChild(mainMedia);
    };
    
    const delBtn = document.createElement('button');
    delBtn.className = 'delete-btn';
    delBtn.innerHTML = '×';
    delBtn.onclick = (e) => {
        e.stopPropagation();
        deleteFromHistory(item.id, div);
    };
    
    div.appendChild(media);
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

document.getElementById('toggle_password').onclick = function() {
    const pass_input = document.getElementById('password');
    if (pass_input.type === 'password') {
        pass_input.type = 'text';
        this.innerText = 'Hide';
    } else {
        pass_input.type = 'password';
        this.innerText = 'Show';
    }
};

async function generate() {
    const start_time = performance.now();
    const prompt_text = document.getElementById('prompt').value;
    const negative_prompt_text = document.getElementById('negative_prompt').value;
    const width = parseInt(document.getElementById('width').value);
    const height = parseInt(document.getElementById('height').value);
    const length = parseInt(document.getElementById('length').value);
    const fps = parseInt(document.getElementById('fps').value);
    let seed = parseInt(document.getElementById('seed').value);
    
    if (seed === -1) {
        seed = Math.floor(Math.random() * 1000000000000000);
    }

    const generate_btn = document.getElementById('generate');
    const status_div = document.getElementById('status');
    const video_container = document.getElementById('video-container');

    generate_btn.disabled = true;
    status_div.innerText = 'Loading workflow...';
    video_container.innerHTML = '';

    try {
        const response = await fetch('resource/workflow.json');
        let api_workflow = await response.json();

        // Update workflow parameters based on Wan 2.2 workflow structure
        // Prompt
        if (api_workflow["89"]) api_workflow["89"].inputs.text = prompt_text;
        
        // Negative Prompt
        if (api_workflow["72"]) api_workflow["72"].inputs.text = negative_prompt_text;
        
        // Size & Length
        if (api_workflow["74"]) {
            api_workflow["74"].inputs.width = width;
            api_workflow["74"].inputs.height = height;
            api_workflow["74"].inputs.length = length;
        }

        // FPS
        if (api_workflow["88"]) api_workflow["88"].inputs.fps = fps;

        // Seed
        if (api_workflow["81"]) api_workflow["81"].inputs.noise_seed = seed;
        if (api_workflow["78"]) api_workflow["78"].inputs.noise_seed = seed;

        document.getElementById('debug_request').innerText = JSON.stringify(api_workflow, null, 2);

        status_div.innerText = 'Queueing prompt...';
        const queued = await queue_prompt(api_workflow);
        const prompt_id = queued.prompt_id;

        status_div.innerText = 'Waiting for generation...';
        
        let completed = false;
        while (!completed) {
            const history = await get_history(prompt_id);
            if (history[prompt_id]) {
                completed = true;
                const end_time = performance.now();
                document.getElementById('debug_time').innerText = ((end_time - start_time) / 1000).toFixed(2) + ' seconds';
                document.getElementById('debug_response').innerText = JSON.stringify(history[prompt_id], null, 2);

                const outputs = history[prompt_id].outputs;
                let found = 0;
                for (const node_id in outputs) {
                    const node_output = outputs[node_id];
                    
                    const all_outputs = [
                        ...(node_output.videos || []),
                        ...(node_output.gifs || []),
                        ...(node_output.images || [])
                    ];

                    for (const data of all_outputs) {
                        const blob = await get_file_blob(data.filename, data.subfolder, data.type);
                        const url = URL.createObjectURL(blob);
                        
                        const is_video = data.filename.endsWith('.mp4') || 
                                       data.filename.endsWith('.webm') || 
                                       node_output.animated?.[0] === true;

                        if (is_video) {
                            const video = document.createElement('video');
                            video.src = url;
                            video.controls = true;
                            video.autoplay = true;
                            video.loop = true;
                            video.className = 'generated-video';
                            video_container.appendChild(video);
                            saveToHistory(blob, prompt_text, 'video');
                        } else {
                            const img = document.createElement('img');
                            img.src = url;
                            img.className = 'generated-video'; 
                            video_container.appendChild(img);
                            saveToHistory(blob, prompt_text, 'image');
                        }
                        found++;
                    }
                }

                if (found > 0) {
                    status_div.innerText = `Done! Generated ${found} item(s).`;
                } else {
                    status_div.innerText = 'Generation failed: No output found.';
                }
            } else {
                await new Promise(r => setTimeout(r, 2000));
            }
        }
    } catch (error) {
        console.error(error);
        status_div.innerText = 'Error: ' + error.message;
    } finally {
        generate_btn.disabled = false;
    }
}

document.getElementById('generate').onclick = generate;

function save_config() {
    const config = {
        server_ip: document.getElementById('server_ip').value,
        username: document.getElementById('username').value,
        password: document.getElementById('password').value,
        width: document.getElementById('width').value,
        height: document.getElementById('height').value,
        length: document.getElementById('length').value,
        fps: document.getElementById('fps').value,
        seed: document.getElementById('seed').value,
        prompt: document.getElementById('prompt').value,
        negative_prompt: document.getElementById('negative_prompt').value
    };
    localStorage.setItem('wan22_config', JSON.stringify(config));
}

function load_config() {
    const saved = localStorage.getItem('wan22_config');
    if (saved) {
        const config = JSON.parse(saved);
        if (config.server_ip) document.getElementById('server_ip').value = config.server_ip;
        if (config.username) document.getElementById('username').value = config.username;
        if (config.password) document.getElementById('password').value = config.password;
        if (config.width) document.getElementById('width').value = config.width;
        if (config.height) document.getElementById('height').value = config.height;
        if (config.length) document.getElementById('length').value = config.length;
        if (config.fps) document.getElementById('fps').value = config.fps;
        if (config.seed) document.getElementById('seed').value = config.seed;
        if (config.prompt) document.getElementById('prompt').value = config.prompt;
        if (config.negative_prompt) document.getElementById('negative_prompt').value = config.negative_prompt;
    }
}

['server_ip', 'username', 'password', 'width', 'height', 'length', 'fps', 'seed', 'prompt', 'negative_prompt'].forEach(id => {
    document.getElementById(id).addEventListener('input', save_config);
});

window.addEventListener('load', () => {
    load_config();
    initDB().then(loadHistory);
});
