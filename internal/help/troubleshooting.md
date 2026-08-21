# Troubleshooting Guide for tgrun

Common issues and their solutions when using the CYMERTEK Trace Generator.

## GPU-Related Issues

### Error: "CUDA not available" or "nvcc not found"

**Cause:** CUDA toolkit or NVIDIA driver not installed.

**Solution:**
```bash
# Check if nvidia-smi works
nvidia-smi

# If it fails, install drivers:
sudo apt-get update
sudo apt-get install -y nvidia-driver-580

# Install CUDA toolkit:
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-0

# Verify nvcc is available:
nvcc --version
```

### Error: "No CUDA devices detected"

**Cause:** GPUs not recognized by system or drivers not loaded.

**Solution:**
```bash
# Check if GPU modules are loaded
lsmod | grep nvidia

# If empty, load them manually:
sudo modprobe nvidia
sudo modprobe nvidia_uvm
sudo modprobe nvidia_modeset

# Verify with nvidia-smi:
nvidia-smi

# If still failing, check system logs:
dmesg | grep -i nvidia
journalctl -k | grep -i nvidia
```

### Error: "CUDA library not found" during compilation

**Cause:** CUDA libraries not in linker path.

**Solution:**
```bash
# Add CUDA to library path
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Make permanent (add to ~/.bashrc):
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Refresh system cache:
sudo ldconfig
```

### Error: "Permission denied" when accessing GPU

**Cause:** User not in required groups.

**Solution:**
```bash
# Add user to video and render groups
sudo usermod -aG video,$USER
sudo usermod -aG render,$USER

# Log out and back in for changes to take effect
```

## Compilation Issues

### Error: "Failed to compile CUDA code"

**Cause:** nvcc compilation errors or incompatible GPU architecture.

**Solution:**
```bash
# Check nvcc version compatibility
nvcc --version

# Verify GPU compute capability matches requirement (7.0+)
nvidia-smi --query-gpu=name,compute_cap --format=csv

# If using older GPU, consider CPU fallback:
./tgrun example.mp --backend cpu
```

### Error: "Out of memory" during CUDA execution

**Cause:** Insufficient GPU VRAM for the trace generation workload.

**Solution:**
```bash
# Reduce scope value to decrease memory usage
./tgrun example.mp --scope 100 --gpus 0

# Use fewer GPUs if multiple are specified
./tgrun example.mp --gpus 0

# Monitor GPU memory usage:
watch -n 1 nvidia-smi
```

## Runtime Issues

### Error: "Generated CUDA code but no output produced"

**Cause:** Compilation succeeded but execution failed silently.

**Solution:**
```bash
# Run with verbose output to see detailed errors
./tgrun example.mp --gpus 0 -v

# Check if temporary files were created
ls /tmp/tgrun-gpu-*

# Manually compile generated code for debugging:
cd /tmp/tgrun-gpu-*/
nvcc -o test_gpu *.cu
./test_gpu
```

### Performance is slower than expected

**Cause:** GPU not being utilized efficiently.

**Solution:**
```bash
# Monitor actual GPU utilization during execution
nvidia-smi dmon

# Check if multiple GPUs are actually being used:
./tgrun example.mp --gpus 0,1 -v

# Increase scope to better utilize parallelism:
./tgrun example.mp --scope 1000 --gpus 0
```

## Platform-Specific Issues

### macOS Users

**Note:** CUDA is not supported on macOS. Use CPU backend only.

```bash
./tgrun example.mp --backend cpu
```

For GPU development on Mac, consider using Docker with NVIDIA container runtime:
```bash
docker run --gpus all -v $(pwd):/app nvidia/cuda:12.0-devel-ubuntu ./tgrun /app/example.mp --gpus 0
```

### WSL2 (Windows Subsystem for Linux)

**Note:** WSL2 has limited GPU support. Ensure you're using WSL2 with proper NVIDIA driver integration.

```bash
# Verify WSL2 GPU access
nvidia-smi

# If not working, update to latest NVIDIA drivers for WSL
# Visit: https://developer.nvidia.com/cuda-wsl
```

## Getting Help

If none of these solutions work:

1. Collect diagnostic information:
   ```bash
   nvidia-smi > nvidia-smi.txt 2>&1
   nvcc --version > nvcc-version.txt 2>&1
   uname -a > system-info.txt 2>&1
   ./tgrun example.mp --gpus 0 -v > tgrun-output.txt 2>&1
   ```

2. Check the [CYMERTEK documentation](https://docs.cymertek.com) for additional resources

3. Report issues with all diagnostic files attached

## Useful Commands Reference

```bash
# List all available GPUs
nvidia-smi -L

# Show GPU topology
nvidia-smi topo -m

# Monitor real-time GPU metrics
watch -n 1 nvidia-smi

# Check CUDA version
nvcc --version

# Test GPU compute capability
./tgrun preloaded-examples/Example01_simple_message_flow.mp --gpus 0 --build-only -v
```
