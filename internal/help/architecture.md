# tgrun Architecture Overview

This document explains how the CYMERTEK Trace Generator (tgrun) works with GPUs, including device selection, compilation, and execution flows.

## High-Level Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│  MP File    │────▶│  Parser      │────▶│ Generator   │────▶│ CUDA Code    │
│ (Input)     │     │ (Lexer+AST)  │     │ (CPU/CUDA)  │     │ (.cu Output) │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
                                                                     │
                                                                     ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│ JSON Output │◀────│ Result JSON  │◀────│ Executable  │◀────│ nvcc Compile │
│ (Final)     │     │ (From GPU)   │     │ (.out)      │     │              │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────┘
```

## Backend Selection Logic

tgrun supports two backends: **CPU** and **CUDA**. The selection happens in this order:

1. **User-specified backend**: `--backend cpu|cuda` forces a specific backend
2. **GPU availability check**: If `--gpus` flag is provided, CUDA is required
3. **Auto-detection**: Checks for nvidia-smi and nvcc on PATH

### Auto-Detection Flowchart

```
Start
  │
  ├─ Is --backend cuda specified? ──Yes──▶ Use CUDA backend
  │                                         │
  No                                        ▼
  │                                   Check CUDA availability:
  │                                     ├─ nvidia-smi in PATH?
  │                                     ├─ nvcc in PATH?
  │                                     └─ GPU detected via nvidia-smi?
  │                                       │
  │                                       ├─ All available? ──▶ Use CUDA
  │                                       │
  │                                       No (fallback)
  │                                         │
  │                                         ▼
  │                                    Check CPU fallback:
  │                                      ├─ Can compile with gcc?
  │                                      └─ Generate CPU traces instead
  │
  ▼
Use CPU backend (default)
```

## GPU Device Selection (`--gpus`)

The `--gpus` flag specifies which GPU devices to use for trace generation.

### Supported Formats

| Format | Example | Description |
|--------|---------|-------------|
| Single device | `--gpus 0` | Use only GPU index 0 |
| Comma-separated | `--gpus 0,1,2` | Use GPUs at indices 0, 1, and 2 |
| Range notation | `--gpus 0-3` | Use GPUs from index 0 to 3 (inclusive) |
| All devices | *(omit flag)* | Use all available GPUs |

### Device Enumeration

When tgrun starts with CUDA backend:

```bash
# Query nvidia-smi for device list
nvidia-smi --query-gpu=index,name,memory.total,compute_cap --format=csv,noheader
```

Output example:
```
0, Tesla V100-SXM2-32GB, 32768MiB, 7.0
1, Tesla V100-SXM2-32GB, 32768MiB, 7.0
2, NVIDIA RTX A6000, 49152MiB, 8.6
```

Each device is assigned an index (0-based) and tgrun validates that requested indices exist before proceeding.

### CUDA_VISIBLE_DEVICES Integration

tgrun respects the `CUDA_VISIBLE_DEVICES` environment variable when set:

```bash
# Only expose GPUs 0 and 2 to CUDA runtime
export CUDA_VISIBLE_DEVICES=0,2
./tgrun example.mp --gpus 0,1  # Uses physical GPU 0 and 2 (now visible as 0 and 1)
```

This is useful for:
- Isolating specific GPUs in multi-GPU systems
- Simulating fewer GPUs than physically present
- Debugging GPU-specific issues

## Compilation Pipeline

When CUDA backend is selected, tgrun performs these steps:

### Step 1: Code Generation

The `CUDAGenerator` produces a complete `.cu` file with:
- Type definitions for trace segments and events
- Kernel functions for parallel trace generation
- Host wrapper functions for device management
- Error handling macros (CUDA_CHECK)

### Step 2: Compilation

```bash
nvcc -O3 -arch=sm_70 -o output_name input.cu -lcudart
```

Flags used:
- `-O3`: Maximum optimization
- `-arch=sm_X`: Target GPU architecture (auto-detected from compute capability)
- `-lcudart`: Link CUDA runtime library

### Step 3: Execution

The compiled binary runs on the specified GPU(s):

```bash
# Set device context before execution
export CUDA_VISIBLE_DEVICES=0,1
./output_name --gpus 0,1 --scope N

# Or use cudaSetDevice() within the program (handled internally)
```

### Step 4: Output Collection

The executable produces JSON output matching the CPU format:
```json
{
  "traces": [
    ["U", 1.0, [["event_name", "A", 1, 0, 0]], [[2, 1]], [], {"VIEWS": []}]
  ]
}
```

## Multi-GPU Parallelism

When multiple GPUs are specified (`--gpus 0,1`), tgrun distributes work:

### Work Partitioning Strategy

```
Total Traces = scope × num_gpus
Traces per GPU = scope (each GPU generates 'scope' independent traces)
```

Each GPU:
1. Allocates device memory for its trace segments
2. Launches parallel kernels on its assigned device
3. Copies results back to host memory
4. Merges with other GPUs' output

### Memory Management

- Each GPU manages its own allocation independently
- No cross-GPU communication during generation (embarrassingly parallel)
- Results merged on CPU after all GPUs complete

## Error Handling and Fallbacks

### Hard Failures (CUDA required but unavailable)

When `--gpus` is specified, CUDA is mandatory:

```bash
./tgrun example.mp --gpus 0
# If CUDA not available:
# [ERROR] CUDA backend required but nvcc not found
# [HINT] Run 'tgrun --help setup-gpu' for installation instructions
```

### Soft Failures (CUDA optional, CPU fallback)

When no `--gpus` flag is given and CUDA unavailable:

```bash
./tgrun example.mp
# Falls back to CPU automatically with warning:
# [WARN] CUDA not available, using CPU backend
# [INFO] Generated 1 traces -> output/example.json (cache: ...)
```

### Compilation Errors

If nvcc fails during compilation:

```bash
[ERROR] nvcc compilation failed
[DETAILS] See /tmp/tgrun-gpu-*/compile.log for full error output
[HINT] Run 'tgrun --help troubleshooting' for common issues
```

## Performance Characteristics

### CPU Backend

- **Pros**: No GPU required, works everywhere
- **Cons**: Single-threaded (or limited parallelism via scope)
- **Best for**: Small models, development, systems without GPUs

### CUDA Backend

- **Pros**: Massive parallelism across GPU cores
- **Cons**: Requires NVIDIA GPU + CUDA toolkit
- **Best for**: Large-scale trace generation, production workloads

### Scaling Expectations

| Configuration | Expected Speedup vs CPU |
|---------------|-------------------------|
| 1 GPU (V100) | 5-20× depending on model complexity |
| 2 GPUs | ~2× over single GPU (near-linear) |
| 8 GPUs (DGX) | ~6-7× over single GPU (communication overhead) |

Actual speedup depends on:
- Model size and trace complexity
- Scope value (work per GPU)
- PCIe bandwidth between GPUs (for multi-GPU systems)

## File Structure Reference

```
tgrun/
├── cmd/tgrun/main.go          # Entry point, flag parsing, orchestration
├── internal/
│   ├── generator/
│   │   ├── cpu.go             # CPU trace generation backend
│   │   └── cuda.go            # CUDA code generator (produces .cu files)
│   ├── parser/
│   │   ├── grammar.go         # MP file grammar definitions
│   │   ├── lexer.go           # Tokenizer for MP syntax
│   │   └── mp_parser.go       # Parser producing AST from tokens
│   ├── model/
│   │   └── marshal.go         # JSON serialization utilities
│   └── output/
│       └── json.go            # Output formatting helpers
├── help/                      # Embedded documentation (offline reference)
│   ├── setup-gpu.md           # GPU installation guide
│   ├── troubleshooting.md     # Common issues and fixes
│   └── architecture.md        # This file
└── preloaded-examples/        # Sample MP files for testing
    ├── original_examples/
    │   ├── Example01_simple_message_flow.mp
    │   └── ...
    └── models/
        └── ...
```

## Extending tgrun

To add new GPU features or backends:

1. **New backend type**: Implement `Generator` interface in `internal/generator/`
2. **GPU-specific kernels**: Modify CUDA kernel launch parameters in `cuda.go`
3. **Device selection logic**: Update `selectBackend()` and `parseGpusFlag()` in main.go
4. **Help documentation**: Add markdown files to `help/` directory

For questions or contributions, see the CYMERTEK documentation site.
