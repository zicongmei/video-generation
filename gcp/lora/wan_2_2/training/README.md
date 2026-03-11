# Wan 2.2 LoRA Training

This directory contains scripts to train a LoRA (Low-Rank Adaptation) for the Wan 2.2 Video Generation model.

## Prerequisites

- **GPU**: NVIDIA GPU with at least 24GB VRAM (e.g., L4, A100, H100). For 14B models, memory optimization like gradient checkpointing and quantization is highly recommended.
- **Python**: 3.10 or later.

## Installation

It is recommended to use a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Note: `diffusers` must be installed from the GitHub main branch to support Wan 2.2.

## Configuration

The training is configured via `config.json`. You can use `config.json.example` as a template.

### Config Parameters:

- `person_name`: The unique identifier for the subject (e.g., "LYFLR").
- `instance_prompt`: The prompt template used during training.
- `model_path`: Path to the base model (`.safetensors` file or directory).
- `batch_size`: Number of samples per training step.
- `epochs`: Total number of training passes.
- `learning_rate`: Step size for the optimizer.
- `rank`: The rank of the LoRA (higher rank = more capacity but larger file).

## Usage

1. **Prepare Data**: Place your training images in the `data/` directory. Ensure they are high-quality and consistent.
2. **Setup Config**: Create `config.json` with your desired settings.
3. **Run Training**:

```bash
bash run_training.sh
```

## Memory Optimization

If you encounter `CUDA out of memory` errors:

1. **Free Memory**: Ensure no other processes (like ComfyUI) are using the GPU.
   ```bash
   sudo systemctl stop comfyui
   ```
2. **Reduce Batch Size**: Set `batch_size` to 1 in `config.json`.
3. **Gradient Checkpointing**: This is enabled by default in the script to save memory.
4. **Use 8-bit / 4-bit loading**: (Future update) The script is designed to eventually support `bitsandbytes` for quantization.

## Outputs

The trained LoRA weights will be saved in the `output/` directory in `safetensors` format, compatible with Diffusers and ComfyUI.
