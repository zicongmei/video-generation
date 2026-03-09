# LTX-2.3 Image-to-Video Workflow

This workflow uses the LTX-2.3 models for Image-to-Video (I2V) generation.

## Model Links

**latent_upscale_models**
- [ltx-2.3-spatial-upscaler-x2-1.0.safetensors](https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.0.safetensors)

**checkpoints**
- BF16: [ltx-2.3-22b-dev.safetensors](https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-dev.safetensors)
- FP8: [ltx-2.3-22b-dev-fp8.safetensors](https://huggingface.co/Lightricks/LTX-2.3-fp8/resolve/main/ltx-2.3-22b-dev-fp8.safetensors)

**loras**
- [ltx-2.3-22b-distilled-lora-384.safetensors](https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-distilled-lora-384.safetensors)

**text_encoders**
- [gemma_3_12B_it_fp4_mixed.safetensors](https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors)

## Model Storage Location

```
📂 ComfyUI/
├── 📂 models/
│   ├── 📂 latent_upscale_models/
│   │   └── ltx-2.3-spatial-upscaler-x2-1.0.safetensors
│   ├── 📂 checkpoints/
│   │   ├── ltx-2.3-22b-dev-fp8.safetensors
│   │   └── ltx-2.3-22b-dev.safetensors
│   ├── 📂 loras/
│   │   └── ltx-2.3-22b-distilled-lora-384.safetensors
│   └── 📂 text_encoders/
│       └── gemma_3_12B_it_fp4_mixed.safetensors
```
