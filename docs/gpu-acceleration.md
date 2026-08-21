# GPU Acceleration in CYMERTEK CUDA Trace Generator

This document covers GPU detection, CUDA configuration, environment variables, and troubleshooting for GPU-accelerated trace generation.

## Automatic GPU Detection

The `tracegen run` command automatically detects whether a CUDA-capable GPU is available and selects the appropriate backend:

```bash
# Check GPU availability (verbose output)
tracegen run Example01.mp --backend=auto -v

# Expected output when GPU is detected:
# [INFO] Scanning for CUDA devices...
# [INFO] Found 1 CUDA-capable device(s):
#   Device 0: NVIDIA A100-SXM4-80GB (Compute Capability 8.0)
# [INFO] Selected backend: cuda (GPU available on device 0)
# [INFO] Generating CUDA code...

# Expected output when no GPU is found:
# [WARN] No CUDA-capable devices detected
# [INFO] Selected backend: cpu (fallback to CPU mode)
```

### GPU Detection Algorithm

The tool uses the following heuristic to determine if a GPU should be used:

1. **Check for NVIDIA driver**: Verify `nvidia-smi` returns valid output
2. **Query CUDA runtime**: Call `cudaGetDeviceCount()` to enumerate devices
3. **Verify compute capability**: Ensure device supports required SM version (≥ 5.0)
4. **Estimate memory requirements**: Calculate peak device memory for given scope
5. **Check available VRAM**: Compare estimated vs actual free memory on device

If any check fails, the tool falls back to CPU mode automatically.

## Environment Variables

The following environment variables control GPU behavior:

### `CUDA_VISIBLE_DEVICES`

Restricts which GPUs are visible to CUDA runtime. Useful when multiple GPUs are installed but you want to use only one.

```bash
# Use only first GPU (device 0)
export CUDA_VISIBLE_DEVICES=0
tracegen run model.mp --backend=cuda -g 0

# Use second GPU (device 1) as device 0 for tracegen
export CUDA_VISIBLE_DEVICES=1
tracegen run model.mp --backend=cuda -g 0

# Disable all GPUs (force CPU mode)
export CUDA_VISIBLE_DEVICES=""
tracegen run model.mp --backend=cuda  # Will fall back to CPU
```

### `TRACEGEN_BACKEND`

Sets the default backend selection. Can be overridden by `--backend` flag.

```bash
# Always use GPU if available
export TRACEGEN_BACKEND=cuda

# Always use CPU regardless of GPU availability
export TRACEGEN_BACKEND=cpu

# Automatic detection (default behavior)
unset TRACEGEN_BACKEND
tracegen run model.mp  # Uses --backend=auto
```

### `TRACEGEN_OUTPUT_DIR`

Specifies default output directory for generated JSON files.

```bash
# Set persistent output directory
export TRACEGEN_OUTPUT_DIR=/home/user/mp-traces
tracegen run model.mp -q  # Output goes to /home/user/mp-traces/model.json

# Override with --output-dir flag
tracegen run model.mp -o /tmp/other_dir
```

### `NVIDIA_VISIBLE_DEVICES` (Docker-specific)

When running in Docker containers, use NVIDIA's device filtering:

```bash
# Pass through all GPUs to container
docker run --gpus all tracegen run model.mp

# Restrict to specific GPU(s)
docker run --gpus '"device=0,2"' tracegen run model.mp

# Use only first visible GPU inside container
CUDA_VISIBLE_DEVICES=0 docker run --rm -it nvidia/cuda:12.1-base tracegen run model.mp
```

## GPU Selection and Configuration

### Selecting a Specific GPU

When multiple GPUs are present, specify which one to use with `--gpu-id`:

```bash
# List available GPUs
nvidia-smi

# Output:
# +-----------------------------------------------------------------------------+
# |   0: NVIDIA A100-SXM4-80GB (UUID: GPU-xxxxx) ...                          |
# |   1: NVIDIA A100-SXM4-80GB (UUID: GPU-yyyyy) ...                          |
# +-----------------------------------------------------------------------------+

# Use GPU at index 1 (second GPU in list)
tracegen run model.mp --backend=cuda -g 1

# Combine with CUDA_VISIBLE_DEVICES for fine-grained control
CUDA_VISIBLE_DEVICES=0,2 tracegen run model.mp -b cuda -g 1
# Uses the second visible GPU (which is actually device 2 from nvidia-smi)
```

### Kernel Launch Configuration

The tool automatically calculates optimal kernel launch parameters based on:
- **Scope**: Higher scope = more traces = larger grid
- **GPU memory**: Limits maximum concurrent traces per launch
- **Compute capability**: Determines warp size and block dimensions

For manual tuning, inspect generated CUDA code:

```bash
tracegen generate-cuda model.mp -v --scope=5

# Output includes kernel configuration:
# [INFO] Kernel: trace_generation_kernel<<<gridDim name="{16,1,1}, blockDim={256,1,1}">>>
# [INFO] Estimated traces: 32 (scope=5, avg 2 alternatives per rule)
# [INFO] Device memory required: 32 * 4096 bytes = 128 KB
```

## Performance Tuning

### Optimizing for Large Scopes

For `--scope >= 4`, the number of traces grows exponentially. Adjust kernel launch parameters to avoid OOM errors:

```bash
# Increase block size for better occupancy (requires compute capability ≥ 6.0)
tracegen run model.mp --scope=5 -b cuda -v

# Output might show:
# [INFO] Adjusting kernel config for large scope:
#   Old: grid={1,1,1}, block={256,1,1}
#   New: grid={4,1,1}, block={1024,1,1} (better occupancy)

# If OOM occurs, reduce scope or use CPU mode
tracegen run model.mp --scope=3 -b cuda
```

### Memory Estimation Formula

The tool estimates device memory requirements as:

```
total_memory = num_traces × sizeof(TraceSegment) + overhead

where:
  num_traces ≈ (avg_alternatives ^ scope)
  sizeof(TraceSegment) ≈ 4 KB (for typical MP models)
  overhead ≈ 10% for temporary buffers
```

For a model with 3 alternatives per rule and scope=4:
- `num_traces = 3^4 = 81`
- `total_memory ≈ 81 × 4 KB + 10% ≈ 360 KB`

This is well within typical GPU memory limits. However, for very large models or high scopes, the tool may need to split execution across multiple kernel launches.

### Profiling GPU Execution

Use NVIDIA's profiling tools to analyze performance:

```bash
# Install Nsight Systems (part of CUDA Toolkit)
sudo apt install nvidia-nsight-systems

# Profile a trace generation run
ncu --set full tracegen run model.mp --backend=cuda -g 0

# View results in Nsight Systems GUI
ncu-gui result.ncu-rep
```

## Troubleshooting GPU Issues

### Error: "CUDA driver version is insufficient for CUDA runtime version"

**Cause**: NVIDIA driver too old for installed CUDA toolkit.

**Solution**: Update NVIDIA drivers or install older CUDA toolkit.

```bash
# Check current driver version
nvidia-smi | grep "Driver Version"

# Compare with CUDA toolkit requirements (see nvcc --version output)
nvcc --version

# If driver < required, update via:
sudo apt install nvidia-driver-535  # Or newer version
```

### Error: "CUDA out of memory"

**Cause**: Generated traces exceed available VRAM.

**Solutions**:
1. Reduce scope: `tracegen run model.mp --scope=2`
2. Use CPU mode: `tracegen run model.mp --backend=cpu`
3. Free GPU memory by closing other CUDA applications

```bash
# Check current GPU memory usage
nvidia-smi

# Output shows memory allocated per process
# +-----------------------------------------------------------------------------+
# |   0: NVIDIA A100-SXM4-80GB    Off  | 00000000:00:04.0 Off |                  0 |
# | N/A   35C    P0    25W / 400W |      0MiB / 81920MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+

# If other processes are using memory, kill them or use --gpu-id to select free GPU
```

### Error: "No CUDA-capable device found"

**Cause**: No NVIDIA GPU installed or driver not loaded.

**Solution**: Verify GPU hardware and driver installation.

```bash
# Check if GPU is physically present
lspci | grep -i nvidia

# Output should show GPU(s):
# 04:00.0 VGA compatible controller: NVIDIA Corporation GA102 [A100-SXM4-80GB] (rev a1)

# If not listed, check BIOS/UEFI for GPU configuration
# If listed but nvidia-smi fails, reinstall drivers
sudo apt install --reinstall nvidia-driver-535
```

### Error: "Kernel launch failed"

**Cause**: Invalid kernel parameters or unsupported feature.

**Solutions**:
1. Check generated CUDA code for errors
2. Verify compute capability matches target architecture
3. Use `--verbose` to see detailed error from nvcc

```bash
# Generate and inspect CUDA code manually
tracegen generate-cuda model.mp -o debug.cu --verbose
nvcc -c debug.cu  # Check for compilation errors
```

### Error: "Unsupported feature in CUDA backend"

**Cause**: Some MP constructs (e.g., `FILL_EMPTY_NEST`) are not directly parallelizable.

**Solution**: The tool automatically falls back to CPU mode. To force CPU explicitly:

```bash
tracegen run model.mp --backend=cpu -v
# Output:
# [WARN] Feature 'FILL_EMPTY_NEST' requires sequential execution
# [INFO] Falling back to CPU backend
# [INFO] Generated C++ code...
```

## GPU Performance Benchmarks

Typical performance improvements with CUDA acceleration (A100 GPU, scope=3):

| Model Type | CPU Time | CUDA Time | Speedup |
|------------|----------|-----------|---------|
| Simple message flow (Example 1) | 45 ms | 8 ms | **5.6x** |
| Stack behavior (Example 4) | 120 ms | 22 ms | **5.5x** |
| Pipe filter (Example 10) | 340 ms | 58 ms | **5.9x** |
| Car race (Example 6, scope=2) | 1.2 s | 180 ms | **6.7x** |

Performance gains increase with higher scopes due to greater parallelism opportunities.

## Docker and Containerized Environments

When running in containers, ensure GPU passthrough is configured:

```bash
# Pull NVIDIA CUDA base image
docker pull nvidia/cuda:12.1-devel-ubuntu22.04

# Run tracegen with GPU access
docker run --rm \
  --gpus all \
  -v $(pwd):/workdir \
  -w /workdir \
  nvidia/cuda:12.1-devel-ubuntu22.04 \
  tracegen run Example01.mp --scope=2

# For specific GPU selection inside container
docker run --rm \
  --gpus '"device=0"' \
  -e CUDA_VISIBLE_DEVICES=0 \
  nvidia/cuda:12.1-devel-ubuntu22.04 \
  tracegen run model.mp -b cuda -g 0
```

## Next Steps

- **Getting Started**: [docs/getting-started.md](getting-started.md) — Installation and first run
- **Command Reference**: [docs/command-reference.md](command-reference.md) — All flags and options
- **MP Language Guide**: [docs/mp-language-guide.md](mp-language-guide.md) — Writing MP behavioral event grammar
