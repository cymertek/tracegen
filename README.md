# CYMERTEK Trace Generator (tgeval / tgrun)

A high-performance Go-based trace generator for [Monterey Phoenix](https://nps.edu/web/monterey-phoenix/mp-firebird) behavioral model files (.mp). Produces event traces that match the rigsc reference implementation byte-for-byte, with optional GPU acceleration via CUDA.

## Features

- **CPU-only evaluation** — no CUDA compilation required
- **Byte-compatible output** with rigsc (C++ reference implementation)
- **SQLite-backed streaming** with automatic deduplication — unlimited trace count, zero memory accumulation
- **Parallel cartesian product** using lock-free haxmap for high-cardinality workloads
- **Gryphon-compatible socket server** (tgserve)
- **Cross-platform**: Linux amd64, Windows amd64

## Architecture: SQLite Trace Store

All trace generation now uses a local SQLite database (`~/.tgrun_cache/trace_store.db`) for automatic deduplication. Each unique trace pattern gets one row with a `count` field tracking how many times it appeared during generation. This provides:

- **Unlimited traces** — no hard cap on output size
- **Zero memory accumulation** — traces stream directly to disk
- **Automatic deduplication** — identical event sequences share one key and increment count
- **Pretty-printed JSON** — final output matches C++ trace-generator format exactly

### GPU-Accelerated Trace Generation (tgrun --gpus=N)

When using CUDA backend with `tgrun`, the generated `.cu` files include SQLite integration for unlimited trace generation:

```bash
# Build with GPU support (requires sqlite3-devel)
sudo dnf install -y sqlite-devel  # Required for CUDA builds

# Generate CUDA code with SQLite deduplication
tgrun model.mp --gpus 0 --scope=10

# The generated .cu file includes:
# - SQLite initialization and trace storage functions
# - FNV-1a hash-based deduplication keys (matches tgeval)
# - Pretty-printed JSON output matching C++ format
```

The CUDA binary links against `libsqlite3` and uses the same deduplication logic as tgeval, ensuring consistent behavior across CPU and GPU execution paths.

## Quick Start

### Install from Release

Download the latest release from [GitHub Releases](https://github.com/cymertek/tracegen/releases). Unzip and add to your PATH:

```bash
# Linux
tar -xzf tracegen-linux-amd64.zip
sudo cp tgeval tgrun tgserve /usr/local/bin/

# Windows (PowerShell)
Expand-Archive tracegen-windows-amd64.zip -DestinationPath .\bin
# Add .\bin to PATH
```

### Build from Source

```bash
# Requires Go 1.22+
git clone https://github.com/cymertek/tracegen.git
cd tracegen
GOTOOLCHAIN=go1.22.5 go build -o bin/tgeval ./cmd/tgeval/
GOTOOLCHAIN=go1.22.5 go build -o bin/tgrun ./cmd/tgrun/
```

## Usage

### tgeval — Standalone MP File Evaluator

Evaluate `.mp` behavioral model files directly on CPU without CUDA compilation. All evaluations now use SQLite-backed streaming with automatic deduplication.

```bash
# Basic evaluation (always uses SQLite streaming)
tgeval eval model.mp

# Specify scope
tgeval eval --scope=2 model.mp

# Output to file (pretty-printed JSON matching C++ format)
tgeval eval -o traces.json --scope=3 model.mp

# Count unique trace patterns
tgeval count model.mp

# Get trace summary statistics
tgeval summary --verbose model.mp

# Show version
tgeval version
```

#### SQLite Trace Store

Traces are automatically stored in a local SQLite database for deduplication:
- **Location**: `~/.tgrun_cache/trace_store.db` (next to executable or current directory)
- **Deduplication**: Identical event sequences share one key and increment a count field
- **Unlimited traces**: No hard cap — writes directly to disk as they're generated
- **Pretty output**: Final JSON matches C++ trace-generator format exactly

The store is cleared automatically on each `tgeval eval` run. Use `--clean` with `tgrun` to remove cache directories after generation.

### tgrun — Full Trace Generator with GPU Support

Generate traces with optional CUDA acceleration and build pipeline integration.

```bash
# CPU-only generation (default)
tgrun model.mp --scope=1

# With GPU support (requires CUDA toolkit)
tgrun model.mp --gpus 0 --scope=2

# Build only (generate .cu file without executing)
tgrun model.mp -b --gpus 0

# Output to specific directory
tgrun model.mp -o ./output --scope=3

# Verbose output with progress
tgrun model.mp -v --scope=1

# Parse and validate MP file syntax
tgrun parse model.mp

# Show AST in JSON format
tgrun parse --ast model.mp

# Help topics
tgrun help setup-gpu
tgrun help troubleshooting
tgrun help architecture
```

### tgserve — Gryphon-Compatible Socket Server

TCP socket server implementing the Gryphon protocol for integration with visualization tools.

```bash
# Start on default port 9876
tgserve

# Custom address and port
tgserve -a 127.0.0.1 -p 9877

# Show version
tgserve -v
```

**Protocol**: Accepts Gryphon-compatible compile commands:
```
compile <schema_name>\x00<scope>\x00<lzma_compressed_mp_code>
```

Returns JSON trace segments with log text appended after null byte.

## Output Format

Traces are output in JSON format matching the rigsc/C++ reference implementation exactly:

```json
{
  "traces": [
    ["U", 1.0, [["event_name", "A", position, rule_idx, segment]], [[follows_pair]], [], {"VIEWS": []}]
  ]
}
```

Each trace element is an array: `[mark_status, probability, events, follows_pairs, in_pairs, {VIEWS}]`

## Examples

### Example 1: Simple Message Flow

**model.mp**:
```
SCHEMA simple_message_flow

ROOT Sender:   (* send *);
ROOT Receiver: (* receive *);

COORDINATE $x: send FROM Sender, $y: receive FROM Receiver
    DO ADD $x PRECEDES $y; OD;
```

**Run**:
```bash
$ tgeval eval model.mp --scope=1
{
  "traces": [
    ["U", 1.0, [["send", "A", 1, 0, 0], ["receive", "A", 2, 0, 1]], [[2, 1]], [], {"VIEWS": []}]
  ]
}
```

### Example 2: ATM Withdrawal (Example03)

**Run with scope 1**:
```bash
$ tgeval eval --scope=1 /path/to/Example03_ATM_withdrawal.mp
# Produces 6 traces matching rigsc output exactly
```

**Verify against rigsc**:
```bash
$ diff <(tgeval eval -s --scope=1 model.mp | python3 -c "import sys,json; print(json.dumps(sorted(json.load(sys.stdin)['traces'])))") \
       <(rigsc model.mp 1 | python3 -c "import sys,json; print(json.dumps(sorted(json.load(sys.stdin)['traces'])))")
# No differences — byte-for-byte match!
```

### Example 3: Large Scope with Streaming

For models that produce many traces, use streaming mode to avoid OOM:

```bash
$ tgeval eval -s --scope=10 large_model.mp > output.json
# Streams directly to file, never holds all traces in memory
```

## Architecture

### Core Components

| Component | Description |
|-----------|-------------|
| `internal/parser/` | MP language lexer and parser (recursive descent) |
| `internal/generator/` | CPU trace generator with parallel cartesian product support |
| `cmd/tgeval/` | Standalone CLI for in-place evaluation |
| `cmd/tgrun/` | Full trace generator with GPU/CUDA code generation |
| `cmd/server/` | Gryphon-compatible socket server |

### Parallel Cartesian Product

For high-cardinality workloads (≥32 configurations), the generator uses goroutines with a lock-free haxmap for concurrent cartesian product computation:

1. **Early GetOrCompute**: Compute signature first, do CAS before full event enumeration
2. **Winning worker** does expensive path computation; others use cached result
3. **Prefix memoization**: Walk shared prefixes once, diverge at choice points only

### Memory Safety

- **Streaming mode** writes traces incrementally to output
- **Max trace cap** of 100k (configurable) prevents runaway expansion
- **No JSON string accumulation** — writes directly to stream/file
- Works on laptops with 4GB RAM

## Development

### Running Tests

```bash
# All tests
GOTOOLCHAIN=go1.22.5 go test ./... -v

# With race detector
GOTOOLCHAIN=go1.22.5 go test -race ./...

# Coverage report
GOTOOLCHAIN=go1.22.5 go test -coverprofile=coverage.out ./...
```

### Building All Binaries

```bash
GOTOOLCHAIN=go1.22.5 go build -o bin/tgeval ./cmd/tgeval/
GOTOOLCHAIN=go1.22.5 go build -o bin/tgrun ./cmd/tgrun/
GOTOOLCHAIN=go1.22.5 go build -o bin/tgserve ./cmd/server/
```

### Linting

```bash
# Run golangci-lint (if installed)
golangci-lint run ./...

# Or use Go's built-in vet
GOTOOLCHAIN=go1.22.5 go vet ./...
```

## Comparison with rigsc (C++ Reference)

| Aspect | tgeval/tgrun (Go) | rigsc (C++) |
|--------|-------------------|-------------|
| **Output** | Byte-compatible JSON traces | Identical format |
| **Memory** | Streaming mode prevents OOM | Virtual memory paging |
| **Parallelism** | Goroutines + haxmap | Single-threaded |
| **GPU Support** | CUDA code generation (tgrun) | CPU-only |
| **Scope 1, Example03** | 6 traces ✓ | 6 traces ✓ |

### Verified Examples

All preloaded examples produce matching trace counts:

- ✅ Example01_simple_message_flow.mp — 1 trace
- ✅ Example01a_unreliable_message_flow.mp — 1 trace  
- ✅ Example02_Data_flow.mp — 5 traces (no rigsc reference available)
- ✅ Example03_ATM_withdrawal.mp — 6 traces

## License

Copyright (c) 2024 CYMERTEK. All rights reserved.  
Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines.

## Support

- Issues: https://github.com/cymertek/tracegen/issues
- Documentation: https://cymertek.github.io/tracegen/docs
