# GPU Setup Guide for tgrun

This guide helps you set up CUDA GPU acceleration for the CYMERTEK Trace Generator (tgrun).

## Prerequisites

- NVIDIA GPU with CUDA compute capability 7.0 or higher (V100, T4, RTX 2080, etc.)
- Ubuntu 20.04/22.04/24.04 LTS
- Root/sudo access for driver installation

## Quick Installation (Recommended)

### Step 1: Install NVIDIA Driver

```bash
# Update package list
sudo apt-get update

# Install recommended NVIDIA drivers
sudo ubuntu-drivers install

# OR manually install specific version:
sudo apt-get install -y nvidia-driver-580

# Reboot to load kernel modules
sudo reboot
```

Verify driver installation:
```bash
nvidia-smi
```

You should see output like:
```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 580.173.02   Driver Version: 580.173.02   CUDA Version: 12.6     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  Off  | 00000000:00:04.0 Off |                    0 |
| N/A   35C    P0    28W / 300W |      0MiB / 32768MiB |      0%      Default |
+-----------------------------------------------------------------------------+
```

### Step 2: Install CUDA Toolkit

```bash
# Add NVIDIA package repository
sudo apt-get install -y wget gnupg
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb

# Install CUDA toolkit (version 12.x recommended)
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-0

# OR use the meta-package for latest version:
sudo apt-get install -y cuda
```

Verify installation:
```bash
nvcc --version
```

Expected output:
```
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2023 NVIDIA Corporation
Built on Fri_Jan__6_16:45:21_PST_2023
Cuda compilation tools, release 12.0, V12.0.140
```

### Step 3: Set Environment Variables (Optional)

Add to `~/.bashrc`:
```bash
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
```

Then reload:
```bash
source ~/.bashrc
```

## Verify tgrun GPU Support

Test with a sample MP file:
```bash
./tgrun preloaded-examples/original_examples/Example01_simple_message_flow.mp --gpus 0 -v
```

Expected output:
```
[INFO] Parsed MP file: Example01_simple_message_flow.mp (37 tokens)
[INFO] Selected backend: cuda
[GPU] Device 0: Tesla V100-SXM2-32GB (Compute Capability 7.0, 32768 MiB)
[INFO] Generated CUDA code -> /tmp/tgrun-gpu/...cu
[INFO] Compiled with nvcc
[INFO] Executed on GPU device 0
[INFO] Generated 1 traces -> output/Example01_simple_message_flow.json (cache: ...)
```

## Using Multiple GPUs

Specify multiple GPU indices:
```bash
# Use GPUs 0 and 1
./tgrun Example01_simple_message_flow.mp --gpus 0,1 -v

# Use specific range notation
./tgrun Example01_simple_message_flow.mp --gpus 0-3 -v
```

## Troubleshooting

### "CUDA not available" or "nvcc not found"

**Solution:** Install NVIDIA driver and CUDA toolkit (see steps above).

### "No CUDA devices detected"

Check that GPU drivers are loaded:
```bash
lsmod | grep nvidia
# Should show modules like nvidia, nvidia_uvm, nvidia_modeset

nvidia-smi
# Should list all available GPUs
```

If `nvidia-smi` fails:
- Reboot the system
- Verify GPU is physically seated
- Check dmesg for driver errors: `dmesg | grep -i nvidia`

### "CUDA library not found" during compilation

Ensure CUDA libraries are in your path:
```bash
echo $LD_LIBRARY_PATH
# Should include /usr/local/cuda/lib64 or similar

sudo ldconfig
# Refresh library cache
```

### Permission denied when accessing GPU

Add user to `video` and `render` groups:
```bash
sudo usermod -aG video,$USER
sudo usermod -aG render,$USER
```

Log out and back in for changes to take effect.

## Performance Tips

1. **Use appropriate scope values**: Higher scope = more parallel work, but also more memory
2. **Monitor GPU utilization**: Run `nvidia-smi dmon` in another terminal while tgrun executes
3. **Batch processing**: For large models, process multiple MP files in sequence rather than in parallel to avoid memory pressure

## Uninstallation

If you need to remove CUDA:
```bash
sudo apt-get purge cuda* nvidia-*
sudo apt-get autoremove
sudo rm -rf /usr/local/cuda
```

## Additional Resources

- [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/)
- [CUDA Samples Repository](https://github.com/NVIDIA/CUDASamples)
- [Ubuntu NVIDIA Driver Guide](https://help.ubuntu.com/community/NVIDIADrivers)

---

**Note**: tgrun requires CUDA compute capability 7.0+ (Volta architecture or newer). Older GPUs may not be supported.
