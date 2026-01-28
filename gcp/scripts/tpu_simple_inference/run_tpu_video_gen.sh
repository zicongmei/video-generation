#!/bin/bash
set -e

echo "Setting up TPU environment for Video..."

# Ensure we are in the right directory
cd "$(dirname "$0")"

# Activate virtualenv if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Clean up any lingering processes
pkill -9 python || true

echo "Running Wan2.1 TPU video generation..."

# Default parameters: 81 frames, 480x832
NUM_FRAMES=${1:-81}
HEIGHT=${2:-480}
WIDTH=${3:-832}

python tpu_video_gen.py --num_frames "$NUM_FRAMES" --height "$HEIGHT" --width "$WIDTH"

echo "Done."
