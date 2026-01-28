#!/bin/bash
cd tpu_simple_inference
export HF_TOKEN=<>
export XLA_PYTHON_CLIENT_PREALLOCATE=false
export XLA_PYTHON_CLIENT_ALLOCATOR=platform
export PJRT_DEVICE=TPU
pkill -f tpu_video_gen.py
nohup bash run_tpu_video_gen.sh > run_v12.log 2>&1 &
echo $!
