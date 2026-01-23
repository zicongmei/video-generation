#!/bin/bash
set -ex

# Redirect output to serial port 1 (/dev/ttyS0) for GCP console logging
exec > >(sudo tee -a /dev/ttyS0) 2>&1

PYTHON_CMD="/opt/conda/bin/python3.10"
export PATH="/opt/conda/bin:$PATH"

echo "Starting FlashAttention installation from source using $PYTHON_CMD..."

# Ensure prerequisites are installed for the specified python command
# FlashAttention requires torch to be present during build
$PYTHON_CMD -m pip install torch packaging ninja

# Clone the repository if it doesn't exist
if [ ! -d "flash-attention" ]; then
    git clone https://github.com/Dao-AILab/flash-attention
fi

cd flash-attention
# Clean existing build artifacts
rm -rf build/

# Install the main flash-attention package
echo "Installing FlashAttention (this may take a long time)..."
# Limit architectures to avoid compute_120 error with CUDA 12.4
# L4 is sm_89, A100 is sm_80, H100 is sm_90
export FLASH_ATTN_CUDA_ARCHS="80;86;89;90"
# Also set TORCH_CUDA_ARCH_LIST just in case
export TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0"
export MAX_JOBS=1
$PYTHON_CMD setup.py install --user

# Optional: Install additional kernels
echo "Installing csrc/layer_norm..."
cd csrc/layer_norm && $PYTHON_CMD setup.py install --user
cd ../..

echo "Installing csrc/rotary..."
cd csrc/rotary && $PYTHON_CMD setup.py install --user
cd ../..

echo "FlashAttention installation complete!"
