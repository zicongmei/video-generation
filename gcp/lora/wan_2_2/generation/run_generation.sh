#!/bin/bash
set -e

# Configuration paths
GEN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRAIN_DIR="$(cd "$GEN_DIR/../training" && pwd)"
CONFIG_FILE="$GEN_DIR/config.json"
LORA_PATH="$TRAIN_DIR/output"
OUTPUT_DIR="$GEN_DIR/output"
VENV_DIR="$GEN_DIR/venv"
BASE_PYTHON="/root/ComfyUI/venv/bin/python"
PYTHON_BIN="$VENV_DIR/bin/python"
TIMING_LOG="$HOME/timing.log"

echo "Setting up local venv for Wan 2.2 video generation using $BASE_PYTHON..."

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    sudo "$BASE_PYTHON" -m venv "$VENV_DIR"
    sudo "$PYTHON_BIN" -m pip install --upgrade pip
    sudo "$PYTHON_BIN" -m pip install -r "$GEN_DIR/requirements.txt"
fi

# Default prompt (can be overridden)
PROMPT="${1:-"{person_name} is smiling, cinematic"}"

echo "Starting Wan 2.2 video generation for persona using LoRA from $LORA_PATH..."
START_TIME=$(date +%s)
echo "Generation started at: $(date) (Optimized, 4-step Light LoRA)" >> "$TIMING_LOG"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the generation script
sudo "$PYTHON_BIN" "$GEN_DIR/generate_wan_video.py" \
    --config "$CONFIG_FILE" \
    --lora_path "$LORA_PATH" \
    --prompt "$PROMPT" \
    --output_dir "$OUTPUT_DIR" \
    --num_frames 81 \
    --steps 4

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "Generation ended at: $(date)" >> "$TIMING_LOG"
echo "Generation duration: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" >> "$TIMING_LOG"

echo "Generation completed. Results are in $OUTPUT_DIR"


