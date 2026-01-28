import jax
import jax.numpy as jnp
from jax import random

# 1. Initialize the TPU
# In a Colab or Cloud TPU environment, this detects the TPU devices
devices = jax.devices()
print(f"Devices found: {devices}")

# 2. Define a simple inference function
def predict(params, x):
    w, b = params
    return jnp.dot(x, w) + b

# 3. Compile the function for the TPU using XLA
# This is crucial: the first call will be slow (compilation), 
# but subsequent calls will be lightning fast.
tpu_predict = jax.jit(predict)

# 4. Setup Mock Data and Parameters
key = random.PRNGKey(0)
k1, k2, k3 = random.split(key, 3)

# Weight matrix (e.g., 512 -> 256) and bias
weights = random.normal(k1, (512, 256))
bias = random.normal(k2, (256,))
params = (weights, bias)

# Input data (Batch of 128)
input_data = random.normal(k3, (128, 512))

# 5. Run Inference
# JAX automatically handles the transfer to the TPU memory
output = tpu_predict(params, input_data)

print(f"Output shape: {output.shape}")
print(f"Output device: {output.device}") # Should show TPU:0
