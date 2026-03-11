#!/bin/bash
set -e

# Configuration paths
TRAIN_DIR="$HOME/gcp/lora/wan_2_2/training"
CONFIG_FILE="$TRAIN_DIR/config.json"
DATA_DIR="$TRAIN_DIR/data"
OUTPUT_DIR="$TRAIN_DIR/output"
PYTHON_BIN="/root/ComfyUI/venv/bin/python"

echo "Starting Wan 2.2 LoRA training using configuration from $CONFIG_FILE..."

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the training script with the config file using the specific python environment
# Note: Using the python bin directly, may need sudo depending on /root/ permissions
sudo "$PYTHON_BIN" "$TRAIN_DIR/train_wan_lora.py" \
    --config "$CONFIG_FILE" \
    --data_dir "$DATA_DIR" \
    --output_dir "$OUTPUT_DIR"

echo "Training completed. LoRA weights are in $OUTPUT_DIR"
