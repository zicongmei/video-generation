#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/AI-Hypercomputer/maxdiffusion"
INSTALL_DIR="$HOME/maxdiffusion"
HF_CACHE_DIR="$HOME/maxdiffusion_hf_cache"
OUTPUT_DIR="$HOME/output_videos_wan"
JAX_CACHE_DIR="$HOME/jax_cache"

mkdir -p "$HF_CACHE_DIR" "$OUTPUT_DIR" "$JAX_CACHE_DIR"

echo "Checking system dependencies..."
if ! command -v python3.12 &> /dev/null; then
    echo "Installing Python 3.12..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.12 python3.12-venv python3.12-dev python3-pip git
fi

echo "Cloning MaxDiffusion..."
if [ ! -d "$INSTALL_DIR" ]; then
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

echo "Setting up virtual environment..."
if [ -d "venv" ]; then
    VENV_VER=$(venv/bin/python --version 2>&1 | awk '{print $2}')
    if [[ ! "$VENV_VER" =~ ^3\.12 ]]; then
        echo "Old venv version $VENV_VER is not 3.12. Deleting..."
        rm -rf venv
    fi
fi
if [ ! -d "venv" ]; then
    python3.12 -m venv venv
fi
source venv/bin/activate

echo "Updating pip and installing core packages..."
pip install --upgrade pip
pip install packaging

echo "Installing JAX for TPU..."
pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html

echo "Installing requirements..."
pip install -r requirements.txt

echo "Installing MaxDiffusion..."
pip install -e .

echo "Environment diagnostics:"
which python
python --version
python -c "import packaging; print('packaging version:', packaging.__version__)"
python -c "import maxdiffusion; print('maxdiffusion found')"

echo "Starting Wan2.2 Text2Vid Inference..."
export HF_HUB_CACHE="$HF_CACHE_DIR"
export LIBTPU_INIT_ARGS="--xla_tpu_enable_async_collective_fusion=true --xla_tpu_enable_async_collective_fusion_fuse_all_reduce=true --xla_tpu_enable_async_collective_fusion_multiple_steps=true --xla_tpu_overlap_compute_collective_tc=true --xla_enable_async_all_reduce=true"
export HF_HUB_ENABLE_HF_TRANSFER=1
export PYTHONPATH="$INSTALL_DIR/src:$PYTHONPATH"

# Run inference
python src/maxdiffusion/generate_wan.py \
  src/maxdiffusion/configs/base_wan_27b.yml \
  attention="flash" \
  num_inference_steps=50 \
  num_frames=81 \
  width=1280 \
  height=720 \
  jax_cache_dir="$JAX_CACHE_DIR" \
  per_device_batch_size=1 \
  ici_data_parallelism=1 \
  ici_fsdp_parallelism=1 \
  flow_shift=5.0 \
  enable_profiler=False \
  run_name=wan2.2-test-cli \
  output_dir="$OUTPUT_DIR" \
  fps=16 \
  flash_min_seq_length=0 \
  flash_block_sizes='{"block_q" : 3024, "block_kv_compute" : 1024, "block_kv" : 2048, "block_q_dkv": 3024, "block_kv_dkv" : 2048, "block_kv_dkv_compute" : 2048, "block_q_dq" : 3024, "block_kv_dq" : 2048 }' \
  seed=118445 \
  prompt="A cinematic shot of a futuristic city with flying cars at sunset."
