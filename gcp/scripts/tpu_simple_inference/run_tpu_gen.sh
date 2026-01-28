#!/bin/bash
# run_tpu_gen.sh for FLUX.1 on v6e TPU

# Exit on error
set -e

# Arguments
NUM_IMAGES=${1:-1}
BATCH_SIZE=${2:-1}

echo "Setting up TPU environment..."

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    python3.11 -m venv venv
fi

# Activate venv
source venv/bin/activate

# Upgrade pip
# pip install --upgrade pip

# Install requirements
# Using torch_xla for FLUX.1 on v6e
# pip install torch==2.5.1 torchvision==0.20.1 torch_xla[tpu]==2.5.1 -f https://storage.googleapis.com/libtpu-releases/index.html
# pip install diffusers transformers Pillow accelerate

echo "Running FLUX.1 TPU image generation..."
python tpu_image_gen.py --num_images "$NUM_IMAGES" --batch_size "$BATCH_SIZE"

echo "Done."