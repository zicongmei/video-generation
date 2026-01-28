import os
import argparse
import torch
import torch_xla.core.xla_model as xm
from diffusers import FluxPipeline
from PIL import Image
from pathlib import Path
import numpy as np

def post_process_image(image_tensor):
    # Post-processing from diffusers
    # The VAE output is in [-1, 1], we map to [0, 1] then to [0, 255]
    image = (image_tensor / 2 + 0.5).clamp(0, 1)
    image = image.cpu().permute(0, 2, 3, 1).float().numpy()
    image = (image * 255).round().astype("uint8")
    return Image.fromarray(image[0])

def generate_images(num_images):
    # 1. Setup the TPU device
    device = xm.xla_device()
    print(f"Using device: {device}")
    
    # 2. Setup the model and pipeline
    model_id = "lzyvegetable/FLUX.1-schnell"
    
    print(f"Loading model {model_id}...")
    try:
        # Load the pipeline with explicit bfloat16
        pipeline = FluxPipeline.from_pretrained(
            model_id, 
            torch_dtype=torch.bfloat16
        )
        
        print("Moving components to TPU...")
        # Ensure models are moved to TPU and are in bfloat16
        pipeline.transformer.to(device, dtype=torch.bfloat16)
        pipeline.vae.to(device, dtype=torch.bfloat16)
        pipeline.text_encoder.to(device, dtype=torch.bfloat16)
        
        # Keep T5 on CPU, but also in bfloat16 to match
        pipeline.text_encoder_2.to("cpu", dtype=torch.bfloat16)
        
        print(f"Pipeline device: {pipeline.device}")
        print(f"Transformer dtype: {pipeline.transformer.dtype}")
        print(f"VAE dtype: {pipeline.vae.dtype}")

    except Exception as e:
        print(f"Error loading model: {e}")
        import traceback
        traceback.print_exc()
        return

    # 3. Prepare the prompt
    prompt = "A high-tech cyberpunk city street at night, neon signs in various colors, rain puddles reflecting the lights, ultra-detailed, 8k resolution"
    
    output_dir = Path("output_images_flux")
    output_dir.mkdir(exist_ok=True)
    
    print(f"Generating {num_images} images...")
    
    for i in range(num_images):
        print(f"Generating image {i+1}/{num_images}...")
        
        with torch.no_grad():
            print("Encoding prompt...")
            # Move CLIP to CPU temporarily for joint encoding
            pipeline.text_encoder.to("cpu")
            (
                prompt_embeds,
                pooled_prompt_embeds,
                text_ids,
            ) = pipeline.encode_prompt(
                prompt=prompt,
                prompt_2=prompt,
                device="cpu",
                max_sequence_length=512,
            )
            pipeline.text_encoder.to(device)
            
            print("Moving embeddings to TPU and forcing bfloat16...")
            prompt_embeds = prompt_embeds.to(device, dtype=torch.bfloat16)
            pooled_prompt_embeds = pooled_prompt_embeds.to(device, dtype=torch.bfloat16)

            print("Running transformer inference on TPU...")
            height, width = 512, 512
            # Explicitly call the pipeline
            latents = pipeline(
                prompt_embeds=prompt_embeds,
                pooled_prompt_embeds=pooled_prompt_embeds,
                output_type="latent",
                num_inference_steps=4,
                guidance_scale=0.0,
                width=width,
                height=height,
            ).images
            
            print(f"Latents dtype before decode: {latents.dtype}")
            # Force latents to bfloat16 before VAE decode to match VAE weights
            latents = latents.to(device, dtype=torch.bfloat16)
            
            # Unpack latents
            latents = pipeline._unpack_latents(
                latents, 
                height, 
                width, 
                pipeline.vae_scale_factor
            )
            
            print(f"Unpacked latents shape: {latents.shape}, dtype: {latents.dtype}")
            
            print("Decoding latents with VAE on TPU...")
            vae_output = pipeline.vae.decode(latents, return_dict=False)[0]
            image = post_process_image(vae_output)
        
        path = output_dir / f"flux_tpu_{i}.png"
        image.save(path)
        print(f"Saved: {path}")
        
        # Execute graph
        xm.mark_step()

    print(f"Successfully generated {num_images} images in total.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate images using FLUX.1 on TPU with torch_xla.")
    parser.add_argument(
        "--num_images", 
        type=int, 
        default=1, 
        help="Number of images to generate (default: 1)"
    )
    
    args = parser.parse_args()
    
    # Set environment variables for TPU
    os.environ["PJRT_DEVICE"] = "TPU"
    # Disable auto-conversion and use explicit dtypes instead
    os.environ["XLA_USE_BF16"] = "0"
    
    try:
        generate_images(args.num_images)
    except Exception as e:
        print(f"Error during generation: {e}")
        import traceback
        traceback.print_exc()