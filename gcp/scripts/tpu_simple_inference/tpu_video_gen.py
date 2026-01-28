import os
import argparse
import torch
import torch_xla.core.xla_model as xm
from diffusers import WanPipeline
from diffusers.utils import export_to_video
from pathlib import Path
import time

def generate_video(num_frames, height, width):
    device = xm.xla_device()
    print(f"Using device: {device}")
    
    # Using 1.3B model for TPU v6e compatibility
    model_id = "Wan-Video/Wan2.1-T2V-1.3B"
    
    print(f"Loading model {model_id}...")
    try:
        pipeline = WanPipeline.from_pretrained(
            model_id, 
            torch_dtype=torch.bfloat16
        )
        
        print("Moving components to TPU...")
        # Move Transformer and VAE to TPU
        pipeline.transformer.to(device, dtype=torch.bfloat16)
        pipeline.vae.to(device, dtype=torch.bfloat16)
        
        # Offload text encoder to CPU to save HBM
        pipeline.text_encoder.to("cpu", dtype=torch.bfloat16)
        
        print(f"Pipeline device: {pipeline.device}")

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
        video = pipeline(
            prompt=prompt,
            negative_prompt=negative_prompt,
            height=height,
            width=width,
            num_frames=num_frames,
            num_inference_steps=30,
            guidance_scale=7.0,
        ).frames[0]
        
    end_time = time.time()
    
    output_path = output_dir / "wan_video_tpu.mp4"
    export_to_video(video, output_path, fps=8)
    
    print(f"Successfully generated video at {output_path}")
    print(f"Total generation time: {end_time - start_time:.2f}s")
    
    # Final step execution
    xm.mark_step()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate video using Wan2.1 on TPU with torch_xla.")
    parser.add_argument("--num_frames", type=int, default=81, help="Number of frames (default: 81)")
    parser.add_argument("--height", type=int, default=480, help="Height (default: 480)")
    parser.add_argument("--width", type=int, default=832, help="Width (default: 832)")
    
    args = parser.parse_args()
    
    os.environ["PJRT_DEVICE"] = "TPU"
    
    try:
        generate_video(args.num_frames, args.height, args.width)
    except Exception as e:
        print(f"Error during generation: {e}")
        import traceback
        traceback.print_exc()
