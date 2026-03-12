import os
import torch
import argparse
import json
import gc
from diffusers import WanPipeline, WanTransformer3DModel, AutoencoderKLWan, FlowMatchEulerDiscreteScheduler
from transformers import T5EncoderModel, T5Tokenizer, BitsAndBytesConfig
from diffusers.utils import export_to_video

def generate(args):
    # Clear cache
    gc.collect()
    torch.cuda.empty_cache()

    # Load config
    with open(args.config, 'r') as f:
        config_data = json.load(f)
    
    person_name = config_data.get("person_name", "person")
    model_path = config_data.get("model_path")
    vae_path = config_data.get("vae_path")
    text_encoder_path = config_data.get("text_encoder_path")
    use_cpu_offload = config_data.get("use_cpu_offload", False)
    load_transformer_in_4bit = config_data.get("load_transformer_in_4bit", True)
    load_text_encoder_in_4bit = config_data.get("load_text_encoder_in_4bit", True)
    
    # Instance prompt - ensure correct replacement
    prompt = args.prompt.replace("{person_name}", person_name)
    print(f"Generating video for: {person_name}")
    print(f"Prompt: {prompt}")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    torch_dtype = torch.bfloat16

    print(f"Loading components with optimized settings (CPU Offload: {use_cpu_offload})...")
    
    # 1. Load Transformer
    print(f"Loading transformer from {model_path}...")
    
    bnb_config = None
    if load_transformer_in_4bit:
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_compute_dtype=torch_dtype,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_use_double_quant=True,
        )
    
    try:
        if model_path.endswith(".safetensors"):
             transformer = WanTransformer3DModel.from_pretrained(
                "Wan-AI/Wan2.1-T2V-14B-Diffusers", 
                subfolder="transformer", 
                quantization_config=bnb_config,
                device_map="auto",
                torch_dtype=torch_dtype
            )
        else:
            transformer = WanTransformer3DModel.from_pretrained(
                model_path, 
                subfolder="transformer", 
                quantization_config=bnb_config,
                device_map="auto",
                torch_dtype=torch_dtype
            )
    except Exception as e:
        print(f"Standard load failed ({e}), trying float16 load...")
        transformer = WanTransformer3DModel.from_single_file(
            model_path, 
            torch_dtype=torch_dtype,
            low_cpu_mem_usage=True,
            device_map="auto"
        )

    # 2. Load VAE
    print(f"Loading VAE from {vae_path}...")
    try:
        vae = AutoencoderKLWan.from_single_file(vae_path, torch_dtype=torch_dtype)
    except Exception:
        vae = AutoencoderKLWan.from_pretrained("Wan-AI/Wan2.1-T2V-14B-Diffusers", subfolder="vae", torch_dtype=torch_dtype)

    # 3. Load Text Encoder
    print(f"Loading Text Encoder...")
    t5_bnb_config = None
    if load_text_encoder_in_4bit:
        t5_bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_compute_dtype=torch_dtype,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_use_double_quant=True,
        )

    tokenizer = T5Tokenizer.from_pretrained("Wan-AI/Wan2.1-T2V-14B-Diffusers", subfolder="tokenizer")
    text_encoder = T5EncoderModel.from_pretrained(
        "Wan-AI/Wan2.1-T2V-14B-Diffusers", 
        subfolder="text_encoder", 
        torch_dtype=torch_dtype,
        quantization_config=t5_bnb_config,
        device_map="auto"
    )

    # 4. Load Scheduler
    print("Loading scheduler...")
    scheduler = FlowMatchEulerDiscreteScheduler.from_pretrained("Wan-AI/Wan2.1-T2V-14B-Diffusers", subfolder="scheduler")

    # 5. Build Pipeline
    print("Building pipeline...")
    pipe = WanPipeline(
        transformer=transformer,
        vae=vae,
        text_encoder=text_encoder,
        tokenizer=tokenizer,
        scheduler=scheduler
    )
    
    if use_cpu_offload:
        print("Enabling model CPU offload...")
        pipe.enable_model_cpu_offload()
    else:
        print("Keeping all components on GPU...")
        pipe.to(device)

    # 6. Load LoRA
    lora_dir = args.lora_path
    weight_name = "adapter_model.safetensors"
    if os.path.isfile(lora_dir):
        weight_name = os.path.basename(lora_dir)
        lora_dir = os.path.dirname(lora_dir)

    print(f"Loading LoRA weights from {lora_dir}, weight_name={weight_name}...")
    pipe.load_lora_weights(lora_dir, weight_name=weight_name)
    
    # 7. Generate
    print("Starting generation...")
    with torch.no_grad():
        output = pipe(
            prompt=prompt,
            negative_prompt=args.negative_prompt,
            num_frames=args.num_frames,
            width=args.width,
            height=args.height,
            num_inference_steps=args.steps,
            guidance_scale=args.guidance_scale,
        )
        video = output.frames[0]

    # 8. Save video
    os.makedirs(args.output_dir, exist_ok=True)
    output_path = os.path.join(args.output_dir, f"generated_{person_name}.mp4")
    export_to_video(video, output_path, fps=args.fps)
    print(f"Video saved to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=str, default="gcp/lora/wan_2_2/generation/config.json")
    parser.add_argument("--lora_path", type=str, default="gcp/lora/wan_2_2/training/output")
    parser.add_argument("--prompt", type=str, default="{person_name} is smiling")
    parser.add_argument("--negative_prompt", type=str, default="low quality, blurry, distorted")
    parser.add_argument("--output_dir", type=str, default="gcp/lora/wan_2_2/generation/output")
    parser.add_argument("--num_frames", type=int, default=81)
    parser.add_argument("--width", type=int, default=832)
    parser.add_argument("--height", type=int, default=480)
    parser.add_argument("--steps", type=int, default=30)
    parser.add_argument("--guidance_scale", type=float, default=5.0)
    parser.add_argument("--fps", type=int, default=16)
    args = parser.parse_args()
    generate(args)
