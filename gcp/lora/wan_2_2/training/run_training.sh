#!/bin/bash
set -e

# Configuration paths
TRAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$TRAIN_DIR/config.json"
DATA_DIR="$TRAIN_DIR/data"
OUTPUT_DIR="$TRAIN_DIR/output"
VENV_DIR="$TRAIN_DIR/venv"
BASE_PYTHON="/root/ComfyUI/venv/bin/python"
PYTHON_BIN="$VENV_DIR/bin/python"
TIMING_LOG="$HOME/timing.log"

echo "Setting up local venv for Wan 2.2 LoRA training using $BASE_PYTHON..."

# Create venv if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    sudo "$BASE_PYTHON" -m venv "$VENV_DIR"
    sudo "$PYTHON_BIN" -m pip install --upgrade pip
    sudo "$PYTHON_BIN" -m pip install -r "$TRAIN_DIR/requirements.txt"
fi

echo "Starting Wan 2.2 LoRA training using configuration from $CONFIG_FILE..."
START_TIME=$(date +%s)
echo "Training started at: $(date)" >> "$TIMING_LOG"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the training script with the config file
sudo "$PYTHON_BIN" "$TRAIN_DIR/train_wan_lora.py" \
    --config "$CONFIG_FILE" \
    --data_dir "$DATA_DIR" \
    --output_dir "$OUTPUT_DIR"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "Training ended at: $(date)" >> "$TIMING_LOG"
echo "Training duration: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds" >> "$TIMING_LOG"

echo "Training completed. LoRA weights are in $OUTPUT_DIR"
