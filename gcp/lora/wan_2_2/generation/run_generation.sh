#!/bin/bash
set -e

# Configuration paths
GEN_DIR="$HOME/gcp/lora/wan_2_2/generation"
TRAIN_DIR="$HOME/gcp/lora/wan_2_2/training"
CONFIG_FILE="$TRAIN_DIR/config.json"
LORA_PATH="$TRAIN_DIR/output"
OUTPUT_DIR="$GEN_DIR/output"
PYTHON_BIN="/root/ComfyUI/venv/bin/python"

# Default prompt (can be overridden)
PROMPT="${1:-A cinematic video of {person_name} walking in a futuristic city, sunset.}"

echo "Starting Wan 2.2 video generation for persona using LoRA from $LORA_PATH..."

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the generation script using the ComfyUI venv
sudo "$PYTHON_BIN" "$GEN_DIR/generate_wan_video.py" \
    --config "$CONFIG_FILE" \
    --lora_path "$LORA_PATH" \
    --prompt "$PROMPT" \
    --output_dir "$OUTPUT_DIR" \
    --num_frames 81 \
    --steps 30

echo "Generation completed. Results are in $OUTPUT_DIR"
