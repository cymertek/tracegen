# tgrun Quick Reference

Common commands and flags for the CYMERTEK Trace Generator (tgrun).

## Basic Usage

```bash
# Run with CPU backend (default)
./tgrun example.mp --scope 100

# Run with GPU acceleration on device 0
./tgrun example.mp --gpus 0

# Use multiple GPUs
./tgrun example.mp --gpus 0,1,2

# Generate only CUDA code (don't compile/run)
./tgrun example.mp --gpus 0 --build-only -o output.cu

# Parse and validate MP file without generating traces
./tgrun parse example.mp

# Show version information
./tgrun --version
```

## Flag Reference

| Flag | Description | Example |
|------|-------------|---------|
| `--gpus=N` | GPU device index/indices to use (required for CUDA backend) | `--gpus 0`, `--gpus 0,1`, `--gpus 0-3` |
| `--scope=N` | Number of iterations per trace segment (default: 1) | `--scope 100` |
| `--backend=cpu\|cuda` | Force specific backend (auto-detects if omitted) | `--backend cuda` |
| `-o FILE` | Output file path for generated CUDA code or traces | `-o output.json` |
| `--build-only` | Generate CUDA files without compiling/executing | `--build-only` |
| `-v`, `--verbose` | Show detailed progress information | `-v` |
| `-q`, `--quiet` | Suppress non-error output | `-q` |
| `-k`, `--clean` | Delete cache directory after run | `-k` |

## Help Commands

```bash
# Show GPU setup instructions (offline)
./tgrun --help setup-gpu

# Show troubleshooting guide (offline)
./tgrun --help troubleshooting

# Show architecture overview (offline)
./tgrun --help architecture

# Show general help
./tgrun --help
```

## Common Workflows

### 1. Quick Test with GPU

```bash
# Verify GPU is accessible
nvidia-smi

# Run a simple example with GPU acceleration
./tgrun preloaded-examples/original_examples/Example01_simple_message_flow.mp \
  --gpus 0 --scope 10 -v
```

### 2. Multi-GPU Parallel Execution

```bash
# Check available GPUs
nvidia-smi -L

# Run with all 8 GPUs on a DGX system
./tgrun large_model.mp --gpus 0,1,2,3,4,5,6,7 --scope 1000 -v
```

### 3. Development Without GPU

```bash
# Fall back to CPU if no GPU available
./tgrun example.mp --backend cpu --scope 50

# Or let tgrun auto-detect and fallback
./tgrun example.mp --scope 50
```

### 4. Generate CUDA Code for Manual Compilation

```bash
# Create a build directory
mkdir -p /tmp/cuda-build && cd /tmp/cuda-build

# Generate .cu file (don't compile yet)
./tgrun example.mp --gpus 0 --build-only -o generated.cu

# Manually compile with custom flags
nvcc -O3 -arch=sm_70 -o trace_gen generated.cu -lcudart

# Run the compiled binary directly
./trace_gen --scope 100
```

### 5. Debugging GPU Issues

```bash
# Enable verbose output to see detailed errors
./tgrun example.mp --gpus 0 -v

# Check if CUDA is properly detected
./tgrun --help setup-gpu | head -20

# Run with CPU fallback to verify MP file works
./tgrun example.mp --backend cpu -v
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CUDA_VISIBLE_DEVICES` | Restrict which GPUs are visible to CUDA runtime | `export CUDA_VISIBLE_DEVICES=0,2` |
| `LD_LIBRARY_PATH` | Add CUDA library paths for linking | `export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH` |

## Output Formats

### JSON Trace Output (Default)

```json
{
  "traces": [
    ["U", 1.0, [["receive", "A", 1, 0, 0], ["send", "A", 2, 1, 0]], [[2, 1]], [], {"VIEWS": []}]
  ]
}
```

### CUDA Code Output (`--build-only`)

```cuda
#include <cuda_runtime.h>
// ... generated kernel code ...
__global__ void trace_generation_kernel(...) { ... }
```

## Performance Tips

- **Use appropriate scope**: Higher scope = more parallel work but also more memory
- **Monitor GPU utilization**: Run `watch -n 1 nvidia-smi` in another terminal
- **Batch processing**: Process multiple MP files sequentially rather than in parallel
- **Single GPU often sufficient**: Adding more GPUs shows diminishing returns beyond 2-3 devices

## File Locations

| Path | Description |
|------|-------------|
| `/tmp/tgrun-gpu-*` | Temporary CUDA build directory (cleared with `-k`) |
| `./output/` | Default output directory for generated traces |
| `help/*.md` | Offline documentation files |
| `preloaded-examples/` | Sample MP files for testing |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (missing args, file not found) |
| 2 | Parse error in MP file |
| 3 | Generation or compilation error |

## Getting Help

If you encounter issues:

1. Run with verbose output: `./tgrun example.mp --gpus 0 -v`
2. Check GPU status: `nvidia-smi`
3. Review help docs: `./tgrun --help setup-gpu` or `./tgrun --help troubleshooting`
4. Collect diagnostics for support:

```bash
nvidia-smi > nvidia-smi.txt 2>&1
nvcc --version > nvcc-version.txt 2>&1
uname -a > system-info.txt 2>&1
./tgrun example.mp --gpus 0 -v > tgrun-output.txt 2>&1
```
