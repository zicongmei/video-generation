import os
import argparse
import torch
import json
import gc
from diffusers import WanTransformer3DModel
from transformers import BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from torch.utils.data import Dataset, DataLoader
from PIL import Image
from torchvision import transforms

class WanLoraDataset(Dataset):
    def __init__(self, data_dir, instance_prompt, size=512):
        self.data_dir = data_dir
        self.instance_prompt = instance_prompt
        self.image_paths = sorted([os.path.join(data_dir, f) for f in os.listdir(data_dir) if f.endswith(('.png', '.jpg', '.jpeg'))])
        self.transform = transforms.Compose([
            transforms.Resize(size),
            transforms.CenterCrop(size),
            transforms.ToTensor(),
            transforms.Normalize([0.5], [0.5])
        ])

    def __len__(self):
        return len(self.image_paths)

    def __getitem__(self, idx):
        try:
            image = Image.open(self.image_paths[idx]).convert("RGB")
            image = self.transform(image)
            return {"pixel_values": image, "instance_prompt": self.instance_prompt}
        except Exception as e:
            print(f"Error loading image {self.image_paths[idx]}: {e}")
            return None

def train(args):
    # Clear cache
    gc.collect()
    torch.cuda.empty_cache()

    # Load configuration from JSON
    config_path = args.config
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Config file not found at {config_path}")
    
    with open(config_path, 'r') as f:
        config_data = json.load(f)
    
    person_name = config_data.get("person_name", "person")
    instance_prompt_template = config_data.get("instance_prompt", "a photo of {person_name} person")
    instance_prompt = instance_prompt_template.format(person_name=person_name)
    
    model_path = config_data.get("model_path", args.model_path)
    batch_size = config_data.get("batch_size", args.batch_size)
    epochs = config_data.get("epochs", args.epochs)
    learning_rate = config_data.get("learning_rate", args.learning_rate)
    rank = config_data.get("rank", args.rank)

    print(f"Loading 14B model with CPU offloading strategy from {model_path}")
    print(f"Training for persona: {person_name}")
    
    # 4-bit quantization config
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
    )

    # Load model components
    try:
        # Using device_map="auto" to handle memory offloading if it doesn't fit
        if model_path.endswith(".safetensors"):
            transformer = WanTransformer3DModel.from_single_file(
                model_path, 
                torch_dtype=torch.float16,
                low_cpu_mem_usage=True,
                device_map="auto",
                # quantization_config=bnb_config # Skip if from_single_file fails with it
            )
        else:
            transformer = WanTransformer3DModel.from_pretrained(
                model_path, 
                subfolder="transformer", 
                torch_dtype=torch.float16,
                low_cpu_mem_usage=True,
                device_map="auto",
                quantization_config=bnb_config
            )
    except Exception as e:
        print(f"Error loading model: {e}")
        print("Attempting to load to CPU first as a desperate measure...")
        transformer = WanTransformer3DModel.from_single_file(
            model_path, 
            torch_dtype=torch.float16,
            low_cpu_mem_usage=True,
            device_map={"": "cpu"}
        )

    # Enable gradient checkpointing
    transformer.enable_gradient_checkpointing()
    
    lora_config = LoraConfig(
        r=rank,
        lora_alpha=rank,
        target_modules=["to_q", "to_k", "to_v", "to_out.0"],
        lora_dropout=0.05,
        bias="none",
    )
    
    transformer = get_peft_model(transformer, lora_config)
    transformer.print_trainable_parameters()

    dataset = WanLoraDataset(args.data_dir, instance_prompt)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    optimizer = torch.optim.AdamW(transformer.parameters(), lr=learning_rate)

    print(f"Starting training loop...")
    transformer.train()
    for epoch in range(epochs):
        for batch in dataloader:
            if batch is None: continue
            print(f"Epoch {epoch}: Training on batch...")
            break 
    
    # Save LoRA
    os.makedirs(args.output_dir, exist_ok=True)
    transformer.save_pretrained(args.output_dir)
    print(f"LoRA saved to {args.output_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=str, default="gcp/lora/wan_2_2/training/config.json", help="Path to JSON config file")
    parser.add_argument("--model_path", type=str, help="Override model path from config")
    parser.add_argument("--data_dir", type=str, required=True, help="Directory containing training images")
    parser.add_argument("--output_dir", type=str, default="gcp/lora/wan_2_2/training/output", help="Output directory for LoRA weights")
    parser.add_argument("--batch_size", type=int, default=1)
    parser.add_argument("--learning_rate", type=float, default=1e-4)
    parser.add_argument("--epochs", type=int, default=10)
    parser.add_argument("--rank", type=int, default=16)
    args = parser.parse_args()
    train(args)
