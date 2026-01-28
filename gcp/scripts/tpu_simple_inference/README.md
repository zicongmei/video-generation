# FLUX.1 Inference on TPU v6e (GCP)

This directory contains scripts and benchmarks for running FLUX.1 image generation on Google Cloud TPU v6e (25GB HBM).

## Benchmark Results (FLUX.1-schnell, 512x512)

Measurements were taken on a single TPU v6e core. The Transformer, VAE, and CLIP models were hosted on the TPU, while the heavy T5 text encoder was offloaded to the CPU to stay within the 25GB HBM limit.

| Batch Size | Total Inference Time | Time per Image | Status |
| :--- | :--- | :--- | :--- |
| 1 | ~135.0s | 135.0s | Success |
| 2 | 128.0s | 64.0s | Success |
| 4 | 182.9s | 45.7s | Success |
| 8 | 153.6s | 19.2s | Success |
| 16 | 186.7s | 11.7s | Success |
| **32** | **208.7s** | **6.5s** | **Optimal** |
| 64 | N/A | N/A | **OOM** (Out of Memory) |

**Key Finding:** Batch size **32** is the optimal configuration, achieving a throughput of **~6.5 seconds per image**.

## Optimization Techniques

1.  **CPU Offloading:** The T5 text encoder (approx. 9GB in bfloat16) is kept on the CPU. Only the Transformer and VAE are moved to the TPU.
2.  **Explicit Dtypes:** To prevent XLA "dtype clashing," all weights and inputs are explicitly cast to `torch.bfloat16`. 
3.  **Manual Embedding Handling:** Prompts are encoded on the CPU, and the resulting embeddings are transferred to the TPU device right before transformer inference to avoid device mismatch errors in the `diffusers` pipeline.
4.  **Latent Unpacking:** Since FLUX uses packed latents, `pipeline._unpack_latents` is used to restore the tensor shape before passing it to the VAE decoder.

## Usage

### Setup
Ensure you have the TPU environment configured with `torch_xla`.

```bash
pip install -r requirements.txt
```

### Running Generation
Use the wrapper script to specify the total number of images and the batch size:

```bash
# Generate 32 images in a single batch
bash run_tpu_gen.sh 32 32
```

## Hardware Limits
The TPU v6e has **25GB of HBM**. 
- At `batch_size=64`, the VAE decoding step attempts to reserve approximately 16GB of workspace memory, triggering a `RESOURCE_EXHAUSTED` error.
- For 512x512 generation, the absolute ceiling for batch size is likely between 32 and 48.
