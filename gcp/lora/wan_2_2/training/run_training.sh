#!/bin/bash
set -e

# Configuration paths
TRAIN_DIR="gcp/lora/wan_2_2/training"
CONFIG_FILE="$TRAIN_DIR/config.json"
DATA_DIR="$TRAIN_DIR/data"
OUTPUT_DIR="$TRAIN_DIR/output"

echo "Starting Wan 2.2 LoRA training using configuration from $CONFIG_FILE..."

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run the training script with the config file
python3 "$TRAIN_DIR/train_wan_lora.py" \
    --config "$CONFIG_FILE" \
    --data_dir "$DATA_DIR" \
    --output_dir "$OUTPUT_DIR"

echo "Training completed. LoRA weights are in $OUTPUT_DIR"
