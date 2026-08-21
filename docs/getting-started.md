# Getting Started with CYMERTEK CUDA Trace Generator

This guide walks you through installing and running your first MP trace generation.

## Prerequisites

### Required: Go 1.21+

The trace generator is written in modern Go. You need a recent version of the Go toolchain installed.

```bash
# Verify installation
go version

# If not installed, download from https://golang.org/dl/
# On Linux (Ubuntu/Debian):
wget -qO- https://go.dev/dl/go1.21.0.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
export PATH=$PATH:/usr/local/go/bin

# On macOS:
brew install go

# On Windows:
# Download installer from https://golang.org/dl/ and run it
```

### Optional: CUDA Toolkit (for GPU acceleration)

To use GPU-accelerated trace generation, you need NVIDIA's CUDA toolkit installed.

#### Linux Installation

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install nvidia-cuda-toolkit
```

**RHEL/CentOS/Fedora:**
```bash
# Install via package manager or download from NVIDIA
wget https://developer.download.nvidia.com/compute/cuda/repos/fedora38/x86_64/cuda-repo-fedora38-12.1-1.x86_64.rpm
sudo dnf install cuda-repo-fedora38-12.1-1.x86_64.rpm
sudo dnf install cuda-toolkit
```

#### macOS Installation

macOS does not officially support CUDA. GPU acceleration is only available on Linux/Windows with NVIDIA GPUs.

```bash
# Install via Homebrew (CUDA toolkit for development, not runtime)
brew install nvidia/cuda/cuda-toolkit
```

#### Windows Installation

Download and run the installer from [NVIDIA Developer](https://developer.nvidia.com/cuda-downloads).

### Verify CUDA Installation

After installing CUDA Toolkit:

```bash
# Check nvcc compiler version
nvcc --version

# Expected output:
# nvcc: NVIDIA (R) Cuda compiler driver
# Copyright (c) 2005-2023 NVIDIA Corporation
# Built on ...
# Cuda compilation tools, release X.Y, VX.Y.Z
```

### Check GPU Availability

```bash
# List available GPUs
nvidia-smi

# Expected output shows your GPU(s):
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 530.30.02    Driver Version: 530.30.02    CUDA Version: 12.1     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |===============================+======================+======================|
# |   0  NVIDIA A100       Off  | 00000000:00:04.0 Off |                    0 |
# | N/A   32C    P0    25W / 400W |      0MiB / 81920MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+
```

## Installation

### Install the Trace Generator

```bash
go install github.com/cymertek/tracegen@latest
```

This installs the `tracegen` binary to `$GOPATH/bin` (typically `~/go/bin`). Add this directory to your PATH if needed:

```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

### Verify Installation

```bash
# Check version
tracegen --version

# Should output something like:
# tracegen v1.0.0 (Go 1.21)
```

## First Run: Generate Traces for Example01.mp

Let's start with the simplest example from the Firebird preloaded collection.

### Step 1: Get an MP File

If you don't have one yet, download a simple example:

```bash
# Create a temporary working directory
mkdir -p /tmp/mp-test && cd /tmp/mp-test

# Download Example01 (simple message flow)
cat > SenderReceiver.mp << 'EOF'
SCHEMA sender_receiver
ROOT Sender: (* send *);
ROOT Receiver: (* receive *);
COORDINATE
    $x: send FROM Sender,
    $y: receive FROM Receiver
DO
    ADD $x PRECEDES $y;
OD;
END SCHEMA;
EOF

echo "Created SenderReceiver.mp"
cat SenderReceiver.mp
```

### Step 2: Run with Auto-compile+run

The `run` command handles everything automatically:

```bash
tracegen run SenderReceiver.mp --scope=1 -v

# Output:
# [INFO] Parsing MP file: SenderReceiver.mp
# [INFO] Backend selected: cuda (GPU available)
# [INFO] Generated CUDA code to /tmp/tracegen-abc123/SenderReceiver.cu
# [INFO] Compiling with nvcc...
# [INFO] Executing trace generator...
# [INFO] Output written to SenderReceiver.json
```

### Step 3: View the Results

```bash
cat SenderReceiver.json | jq .

# Expected output (simplified):
{
  "traces": [
    {
      "mark_status": "U",
      "probability": 1.0,
      "events": [
        {"name": "send", "type": "A", "id": 0},
        {"name": "receive", "type": "A", "id": 1}
      ],
      "follows": [[0, 1]],
      "in_relations": []
    }
  ]
}
```

## Understanding the Output

The JSON output contains:

- **traces**: Array of generated event traces (one per valid execution path)
- **mark_status**: `"U"` = unmarked (default), `"M"` = marked by user
- **probability**: Likelihood of this trace occurring (1.0 if deterministic)
- **events**: List of events with names, types, and unique IDs
  - Type `A` = atomic event, `C` = composite, `R` = root
- **follows**: Pairs `[a, b]` meaning "event a PRECEDES event b"
- **in_relations**: Nested event relationships

## Next Steps

1. Try different scopes: `--scope=2`, `--scope=3` (higher values generate more traces)
2. Explore other examples in the [Firebird preloaded collection](https://wiki.nps.edu/display/MP/Monterey+Phoenix+Home)
3. Read the [Command Reference](command-reference.md) for all options
4. Learn about [GPU acceleration](gpu-acceleration.md) details

## Troubleshooting

### "tracegen: command not found"

Ensure `$GOPATH/bin` is in your PATH:

```bash
export PATH=$PATH:$(go env GOPATH)/bin
# Or add to ~/.bashrc or ~/.zshrc for persistence
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

### "nvcc: command not found"

CUDA toolkit not installed or not in PATH. Install it and verify:

```bash
# Check if nvcc exists anywhere on the system
which nvcc || find /usr -name nvcc 2>/dev/null | head -5

# If found at /usr/local/cuda/bin/nvcc, add to PATH:
export PATH=$PATH:/usr/local/cuda/bin
```

### "CUDA driver version is insufficient"

You have CUDA toolkit installed but no NVIDIA GPU or driver. The tool will automatically fall back to CPU mode:

```bash
# Force CPU mode explicitly
tracegen run SenderReceiver.mp --backend=cpu --scope=1 -v

# Output:
# [INFO] Backend selected: cpu (GPU unavailable)
# [INFO] Generated C++ code...
# [INFO] Compiling with g++...
# [INFO] Executing trace generator...
```

### "Permission denied" on generated executables

The tool creates temporary files in `/tmp/tracegen-<random>/`. Ensure /tmp is writable:

```bash
ls -ld /tmp
drwxrwxrwt  10 root root 4096 Jul 29 12:00 /tmp
# Should show world-writable permissions (the 't' flag)
```

## What's Next?

- **Command Reference**: [docs/command-reference.md](command-reference.md) — All flags and options explained
- **Code Generation**: [docs/code-generation.md](code-generation.md) — How CUDA/CPU code is generated
- **GPU Acceleration**: [docs/gpu-acceleration.md](gpu-acceleration.md) — GPU detection and environment variables
- **MP Language Guide**: [docs/mp-language-guide.md](mp-language-guide.md) — Writing MP behavioral event grammar
