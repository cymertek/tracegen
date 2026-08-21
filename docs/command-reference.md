# Command Reference for CYMERTEK CUDA Trace Generator

Complete documentation of all commands, flags, and options available in `tracegen`.

## Commands Overview

The trace generator provides four main commands:

| Command | Description | Use Case |
|---------|-------------|----------|
| `run` | Auto-compile+run with GPU detection | One-command pipeline for production use |
| `generate-cuda` | Generate CUDA source code only | Manual compilation and execution |
| `generate-cpu` | Generate C++ source code only | CPU-only environments or debugging |
| `parse` | Validate MP file syntax | Syntax checking without trace generation |

## Command: `run` (Auto-compile+Run)

The primary command for generating traces. Handles parsing, code generation, compilation, and execution in a single step.

```bash
tracegen run [mp_file] [flags]
```

### Flags for `run`

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--scope` | `-s` | `1` | Number of event iterations (higher = more traces) |
| `--backend` | `-b` | `auto` | Code generation backend: `cpu`, `cuda`, or `auto` (GPU if available, else CPU) |
| `--gpu-id` | `-g` | `0` | Which GPU to use (0-indexed) when multiple GPUs present |
| `--output-dir` | `-o` | `./output` | Directory for generated JSON output files |
| `--verbose` | `-v` | `false` | Show detailed progress information during execution |
| `--quiet` | `-q` | `false` | Suppress all non-error output |
| `--no-cleanup` | — | `false` | Keep temporary build directory after completion (useful for debugging) |

### Examples

```bash
# Run with automatic GPU detection
tracegen run Example01.mp --scope=2

# Force CPU mode
tracegen run Example04.mp --backend=cpu -s 5

# Use specific GPU device
tracegen run complex_model.mp -b cuda -g 1

# Save to custom output directory
tracegen run model.mp -o /home/user/traces/

# Verbose output with no cleanup (for debugging)
tracegen run debug_test.mp --verbose --no-cleanup

# Quiet mode for scripting
tracegen run batch_model.mp -q
```

## Command: `generate-cuda`

Generate CUDA source code without compiling or executing. Useful for inspecting generated kernels or manual compilation.

```bash
tracegen generate-cuda [mp_file] [flags]
```

### Flags for `generate-cuda`

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--scope` | `-s` | `1` | Iteration scope (affects kernel launch configuration) |
| `--output` | `-o` | stdout | Output file path for generated `.cu` code |
| `--verbose` | `-v` | `false` | Show generation details |

### Examples

```bash
# Generate CUDA code to file
tracegen generate-cuda Example10.mp -s 3 -o pipe_filter.cu

# Inspect generated kernel structure
tracegen generate-cuda complex_model.mp --verbose

# Pipe output for inspection
tracegen generate-cuda model.mp | head -50
```

## Command: `generate-cpu`

Generate C++ source code without compiling or executing. Useful for CPU-only environments or when CUDA is not available.

```bash
tracegen generate-cpu [mp_file] [flags]
```

### Flags for `generate-cpu`

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--scope` | `-s` | `1` | Iteration scope (affects generated loop bounds) |
| `--output` | `-o` | stdout | Output file path for generated `.cpp` code |
| `--verbose` | `-v` | `false` | Show generation details |

### Examples

```bash
# Generate C++ code to file
tracegen generate-cpu Example01.mp -s 2 -o simple_flow.cpp

# Compile and run manually
tracegen generate-cpu model.mp -o model.cpp --verbose
g++ -O3 model.cpp -o model_trace
./model_trace

# View generated code structure
tracegen generate-cpu complex_model.mp | grep -E "^(void|class|#include)"
```

## Command: `parse`

Validate MP file syntax and display parsed AST. Does not generate traces.

```bash
tracegen parse [mp_file] [flags]
```

### Flags for `parse`

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--ast` | `-a` | `false` | Print parsed AST in JSON format (default: human-readable summary) |
| `--verbose` | `-v` | `false` | Show detailed parsing information |

### Examples

```bash
# Validate syntax and show summary
tracegen parse Example01.mp

# Print full AST as JSON
tracegen parse model.mp --ast -o ast.json

# Debug parsing errors
tracegen parse buggy_model.mp -v
```

## Global Flags

These flags apply to all commands:

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--help` | `-h` | — | Show help message for command |
| `--version` | `-V` | — | Print version information and exit |
| `--log-level` | — | `info` | Logging level: `debug`, `info`, `warn`, `error` |

### Examples

```bash
# Show help for run command
tracegen run --help

# Display version
tracegen --version

# Set logging level (useful for debugging)
tracegen run model.mp --log-level=debug
```

## Output File Naming Convention

When generating output files, the tool follows these naming patterns:

| Input File | Output Filename | Location |
|------------|-----------------|----------|
| `Example01.mp` | `Example01.json` | `--output-dir/` or current directory |
| `/path/to/model.mp` | `model.json` | `--output-dir/` |

The output filename matches the MP file basename (without `.mp` extension) with a `.json` suffix.

## Exit Codes

The trace generator uses standard exit codes:

| Code | Meaning |
|------|---------|
| `0` | Success — traces generated and written to output |
| `1` | General error — invalid arguments, file not found, etc. |
| `2` | Parse error — MP file contains syntax errors |
| `3` | Generation error — code generation failed (e.g., unsupported feature) |
| `4` | Compilation error — generated code failed to compile |
| `5` | Runtime error — trace generator crashed during execution |

Check exit codes in scripts:

```bash
tracegen run model.mp || echo "Trace generation failed with exit code $?"
```

## Environment Variable Overrides

Certain flags can be overridden via environment variables. Environment variables take precedence over command-line defaults but not explicit CLI arguments.

| Variable | Corresponding Flag | Description |
|----------|-------------------|-------------|
| `TRACEGEN_BACKEND` | `--backend` | Default backend: `cpu`, `cuda`, or `auto` |
| `CUDA_VISIBLE_DEVICES` | `--gpu-id` | Restrict visible GPUs (comma-separated list) |
| `TRACEGEN_OUTPUT_DIR` | `--output-dir` | Default output directory |

### Examples

```bash
# Set default backend via environment variable
export TRACEGEN_BACKEND=cuda
tracegen run model.mp  # Uses CUDA by default

# Override with explicit flag
tracegen run model.mp --backend=cpu  # CLI wins over env var

# Restrict to specific GPUs
export CUDA_VISIBLE_DEVICES=0,2
tracegen run model.mp -g 1  # Uses GPU at index 1 (device 2)
```

## Integration with Other Tools

### Using with jq for JSON Processing

```bash
# Generate traces and filter by probability
tracegen run model.mp -o traces.json --quiet
cat traces.json | jq '.traces[] | select(.probability > 0.9)'

# Count generated traces
tracegen run model.mp -o output.json --quiet
jq '.traces | length' output.json
```

### Using with diff for Comparison

```bash
# Compare outputs from different scopes
tracegen run model.mp --scope=1 -o scope1.json -q
tracegen run model.mp --scope=2 -o scope2.json -q
diff <(jq . scope1.json) <(jq . scope2.json | head -50)

# Compare with original Firebird output (if available)
firebird-run model.mp 1 > firebird_output.json
tracegen run model.mp --scope=1 -o tracegen_output.json -q
diff <(jq . sort firebird_output.json) <(jq . sort tracegen_output.json)
```

### Using in CI/CD Pipelines

```bash
# Example GitHub Actions snippet
- name: Run MP trace generation
  run: |
    tracegen run tests/*.mp --backend=cpu --output-dir=ci-output/ -q
    jq '.traces | length' ci-output/*.json > trace_counts.txt
    cat trace_counts.txt >> $GITHUB_STEP_SUMMARY

# Example Makefile target
.PHONY: test-traces
test-traces:
	tracegen run tests/model.mp --scope=3 -o /tmp/test_output.json
	diff <(jq . /tmp/test_output.json) <(cat expected_output.json | jq .)
```

## Advanced Usage Patterns

### Batch Processing Multiple MP Files

```bash
# Process all .mp files in a directory
for mp_file in models/*.mp; do
    echo "Processing $mp_file..."
    tracegen run "$mp_file" --scope=2 -o "/tmp/traces/$(basename "${mp_file%.mp}").json" -q
done

# Parallel processing with xargs (limit to 4 concurrent jobs)
ls models/*.mp | xargs -P 4 -I {} tracegen run {} --backend=cuda -q
```

### Using Temporary Build Directory Locally

By default, the tool creates `/tmp/tracegen-<random>/` for intermediate files. To inspect generated code:

```bash
# Run with no-cleanup to preserve build directory
tracegen run model.mp --no-cleanup

# Find and examine the temporary directory
ls -la /tmp/tracegen-*
cat /tmp/tracegen-*/model.cu  # Inspect generated CUDA code
```

### Redirecting Output to Files

```bash
# Capture stdout (progress messages) to a log file
tracegen run model.mp --verbose > build.log 2>&1

# Save stderr separately for debugging
tracegen run model.mp -v 2> debug.log
```

## Common Flag Combinations

| Use Case | Command |
|----------|---------|
| Quick test with GPU | `tracegen run model.mp` |
| Debugging parse errors | `tracegen parse model.mp --ast -v` |
| Production batch processing | `tracegen run model.mp --backend=cuda -q` |
| CI/CD validation | `tracegen run model.mp --backend=cpu --scope=1 -q` |
| Inspect generated code | `tracegen generate-cuda model.mp --verbose` |

For more details, see:
- [Getting Started](getting-started.md) — Installation and first run
- [GPU Acceleration](gpu-acceleration.md) — CUDA and GPU configuration
- [MP Language Guide](mp-language-guide.md) — Writing MP behavioral event grammar
