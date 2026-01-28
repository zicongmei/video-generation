import os
import argparse
import torch
import torch_xla.core.xla_model as xm
from diffusers import WanPipeline
from diffusers.utils import export_to_video
from pathlib import Path
import time
import numpy as np
from PIL import Image
from tqdm import tqdm

def generate_video(num_frames, height, width):
    device = xm.xla_device()
    print(f"Using device: {device}")
    
    model_id = "Wan-AI/Wan2.1-T2V-1.3B-Diffusers"
    
    print(f"Loading model {model_id}...")
    try:
        pipeline = WanPipeline.from_pretrained(
            model_id, 
            torch_dtype=torch.bfloat16
        )
        
        print("Moving components to TPU...")
        pipeline.vae.to(device, dtype=torch.bfloat16)
        pipeline.transformer.to(device, dtype=torch.bfloat16)
        pipeline.text_encoder.to("cpu", dtype=torch.bfloat16)
        
    except Exception as e:
        print(f"Error loading model: {e}")
        import traceback
        traceback.print_exc()
        return

    prompt = "A cinematic shot of a futuristic city with flying cars, neon lights, sunset, high detail, 4k"
    negative_prompt = "blurry, low quality, distorted"
    
    output_dir = Path("output_videos_wan")
    output_dir.mkdir(exist_ok=True)
    
    print(f"Generating video with {num_frames} frames ({width}x{height})...")
    
    start_time = time.time()
    with torch.no_grad():
        # Encode on CPU
        print("Encoding prompt on CPU...")
        prompt_embeds, negative_prompt_embeds = pipeline.encode_prompt(
            prompt, negative_prompt, num_videos_per_prompt=1, device="cpu"
        )
        
        # Move embeddings to TPU
        print("Moving embeddings to TPU...")
        prompt_embeds = prompt_embeds.to(device, dtype=torch.bfloat16)
        negative_prompt_embeds = negative_prompt_embeds.to(device, dtype=torch.bfloat16)

        # Prepare latents on TPU
        print("Preparing latents on TPU...")
        batch_size = 1
        num_channels_latents = pipeline.transformer.config.in_channels
        
        vae_scale_factor_temporal = getattr(pipeline.vae.config, "scale_factor_temporal", 4)
        vae_scale_factor_spatial = getattr(pipeline.vae.config, "scale_factor_spatial", 8)
        
        num_latent_frames = (num_frames - 1) // vae_scale_factor_temporal + 1
        height_latent = int(height) // vae_scale_factor_spatial
        width_latent = int(width) // vae_scale_factor_spatial
        
        shape = (
            batch_size,
            num_channels_latents,
            num_latent_frames,
            height_latent,
            width_latent,
        )
        
        # Create latents on TPU (BF16)
        latents = torch.randn(shape, device=device, dtype=torch.bfloat16)
        
        # Prepare scheduler
        num_inference_steps = 30
        pipeline.scheduler.set_timesteps(num_inference_steps, device=device)
        timesteps = pipeline.scheduler.timesteps
        guidance_scale = 7.0
        
        print("Starting denoising loop...")
        for i, t in enumerate(tqdm(timesteps)):
            latent_model_input = latents
            timestep = t.expand(latents.shape[0])
            
            # Predict noise
            noise_pred = pipeline.transformer(
                hidden_states=latent_model_input,
                timestep=timestep,
                encoder_hidden_states=prompt_embeds,
                return_dict=False,
            )[0]
            
            # Classifier-free guidance
            noise_uncond = pipeline.transformer(
                hidden_states=latent_model_input,
                timestep=timestep,
                encoder_hidden_states=negative_prompt_embeds,
                return_dict=False,
            )[0]
            
            noise_pred = noise_uncond + guidance_scale * (noise_pred - noise_uncond)
            
            # Scheduler step
            latents = pipeline.scheduler.step(noise_pred, t, latents, return_dict=False)[0]
            
            xm.mark_step()
            
        print("Decoding with VAE on TPU...")
        latents = latents.to(torch.bfloat16)
        
        # Manually decode VAE if needed, or use pipeline method but careful with device
        # Using pipeline.vae directly
        
        # We need to handle normalization if pipeline does it
        # In pipeline_wan.py:
        # latents = latents / latents_std + latents_mean
        
        if hasattr(pipeline.vae.config, "latents_mean") and pipeline.vae.config.latents_mean is not None:
             latents_mean = (
                torch.tensor(pipeline.vae.config.latents_mean)
                .view(1, pipeline.vae.config.z_dim, 1, 1, 1)
                .to(latents.device, latents.dtype)
            )
             latents_std = 1.0 / torch.tensor(pipeline.vae.config.latents_std).view(1, pipeline.vae.config.z_dim, 1, 1, 1).to(
                latents.device, latents.dtype
            )
             latents = latents / latents_std + latents_mean
        
        video = pipeline.vae.decode(latents, return_dict=False)[0]
        # video is [B, C, F, H, W]
        
        # Post-process
        video = (video / 2 + 0.5).clamp(0, 1)
        video = video.cpu().permute(0, 2, 3, 4, 1).float().numpy()[0]
        # [F, H, W, C]
        
        video = [Image.fromarray((frame * 255).astype(np.uint8)) for frame in video]
        
    end_time = time.time()
    
    output_path = output_dir / "wan_video_tpu.mp4"
    export_to_video(video, output_path, fps=8)
    
    print(f"Successfully generated video at {output_path}")
    print(f"Total generation time: {end_time - start_time:.2f}s")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate video using Wan2.1 on TPU with torch_xla.")
    parser.add_argument("--num_frames", type=int, default=1, help="Number of frames (default: 1)")
    parser.add_argument("--height", type=int, default=256, help="Height (default: 256)")
    parser.add_argument("--width", type=int, default=256, help="Width (default: 256)")
    
    args = parser.parse_args()
    
    os.environ["PJRT_DEVICE"] = "TPU"
    
    try:
        generate_video(args.num_frames, args.height, args.width)
    except Exception as e:
        print(f"Error during generation: {e}")
        import traceback
        traceback.print_exc()