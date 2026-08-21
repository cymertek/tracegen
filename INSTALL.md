# Installation Guide

Two RPM package variants are available — choose the one that matches your hardware:

| Variant | Package Name | GPU Support | Install Size |
|---------|--------------|-------------|--------------|
| **CPU-only** (default) | `gnu-trace-generator` | No | ~1.9 MB |
| **CUDA GPU** | `gnu-trace-generator-cuda` | NVIDIA GPUs | ~1.9 MB + driver libs (~9.6 MB) |

Both variants install the same four binaries to `/usr/local/bin/`:

- `tgrun` — Trace generator (runs MP files, generates traces or CUDA code)
- `tgfmt` — MP file formatter
- `tglint` — MP language linter with rule numbering and suppression syntax
- `tgserve` — Gryphon-compatible TCP socket server

---

## Option 1: CPU-only Package (no GPU required)

Recommended for development, CI/CD pipelines, and systems without NVIDIA GPUs. Runs entirely on CPU via Go.

```bash
# Install build dependencies (Go compiler + rpmbuild)
sudo dnf install -y go golang-bin gcc-c++ rpm-build

# Build the binaries
make go-build

# Generate RPM package
make rpm-build-cpu

# Install — pulls in only the four tg* binaries, no GPU drivers needed
sudo make rpm-install-cpu
```

**Verify:**
```bash
tgrun --version    # tgrun v1.0.0
tgfmt --help
tglint list-rules  # Shows all 10 rules with A-prefixed numbers
tgserve -v         # tgserve - Gryphon-compatible socket server v1.0.0
```

---

## Option 2: CUDA GPU Package (requires NVIDIA hardware)

For systems with NVIDIA GPUs where you want `tgrun` to detect and use the GPU backend automatically, or to compile generated `.cu` files with `nvcc`.

```bash
# Install build dependencies — this also pulls in nvidia-driver-libs + cuda-toolkit
sudo dnf install -y go golang-bin gcc-c++ rpm-build nvidia-driver-libs cuda-toolkit

# Build the binaries
make go-build

# Generate RPM package (CUDA variant includes NVIDIA dependency declarations)
make rpm-build-cuda

# Install — pulls in tgrun/tgfmt/tglint/tgserve + nvidia-driver-libs automatically
sudo make rpm-install-cuda
```

**Verify:**
```bash
tgrun --version    # tgrun v1.0.0
nvidia-smi         # Should show GPU detected (installed as dependency)
nvcc --version     # CUDA compiler available (installed as dependency)
sqlite3 --version  # SQLite should be available for trace deduplication
```

### SQLite Dependency for CUDA Builds

CUDA binaries use SQLite for unlimited trace generation with automatic deduplication. When building with GPU support:

```bash
# Install sqlite3 development headers (required for CUDA builds with SQLite)
sudo dnf install -y go golang-bin gcc-c++ rpm-build nvidia-driver-libs cuda-toolkit sqlite-devel
```

The generated `.cu` files include `sqlite3.h` and link against `libsqlite3`. This enables:
- **Unlimited trace count** — no memory accumulation in GPU kernels
- **Automatic deduplication** — identical event sequences share one key with incremented count
- **Pretty-printed JSON output** — matches tgeval format exactly

---

## Important: Only install ONE variant

The two packages conflict with each other — they install identical binaries to `/usr/local/bin/`. You cannot have both installed simultaneously.

```bash
# Installing CUDA over CPU will fail:
sudo dnf install gnu-trace-generator-cuda
# → Error: package gnu-trace-generator conflicts with gnu-trace-generator-cuda < 2.0.0

# Installing CPU over CUDA will also fail:
sudo dnf install gnu-trace-generator
# → Error: package gnu-trace-generator-cuda conflicts with gnu-trace-generator < 2.0.0

# To switch between variants, remove the current one first:
sudo dnf remove -y gnu-trace-generator-cuda   # or gnu-trace-generator
sudo dnf install -y gnu-trace-generator       # then install your choice
```

---

## Uninstall

```bash
# Remove whichever variant is installed:
sudo dnf remove -y gnu-trace-generator          # CPU-only
# or
sudo dnf remove -y gnu-trace-generator-cuda     # CUDA (also removes nvidia-driver-libs)
```

---

## Build from Source (without RPM)

For development and testing, you can build directly without packaging:

```bash
make go-build          # Builds tgrun, tgfmt, tglint, tgserve in current directory
make test              # Runs all unit + integration tests
./tgrun example.mp --scope=3 -v   # Run traces directly
```

---

## Quick Reference: What Each Tool Does

| Command | Purpose | Example |
|---------|---------|---------|
| `tgrun <file.mp>` | Generate JSON traces (default — no subcommand needed) | `tgrun model.mp --scope=5 -v` |
| `tgrun <file.mp> -o output.cu` | Generate .cu CUDA source code via `-o` flag | `tgrun model.mp -o model.cu` |
| `tgrun <file.mp> --build-only` | Build CUDA code inline (same as `-o`) | `tgrun model.mp --build-only` |
| `tgrun parse <file.mp>` | Validate syntax and print AST summary | `tgrun parse model.mp --ast` |
| `tgfmt format -w <files...>` | Format MP files in place | `tgfmt format -w models/*.mp` |
| `tglint lint <files...>` | Lint MP files with rule numbering (A001–A010) | `tglint lint --severity=warning model.mp` |
| `tglint list-rules` | List all 10 rules | `tglint list-rules` |
| `tgserve -p <port>` | Start Gryphon socket server | `tgserve -p 9876 &` |

### Caching Behavior

`tgrun` automatically caches trace output in `/tmp/tgrun-<user>-<sha1>/`. The hash is computed from the **parsed schema** (not raw file bytes), so:

- **Comments don't affect caching**: Adding or removing comments produces identical cache hashes
- **Whitespace changes are ignored**: Reformatting the MP file doesn't invalidate the cache
- **Scope matters**: Same file with different `--scope` values gets separate cache entries
- **User isolation**: Each user gets their own cache directory, preventing cross-user collisions

Example:
```bash
# User alice runs demo.mp — creates /tmp/tgrun-alice-bdf82fd0/
$ USER=alice tgrun demo.mp --scope=3
[INFO] Generated 1 traces -> output/demo.json (cache: /tmp/tgrun-alice-bdf82fd0)

# User bob runs the same file — creates /tmp/tgrun-bob-bdf82fd0/ (separate dir!)
$ USER=bob tgrun demo.mp --scope=3
[INFO] Generated 1 traces -> output/demo.json (cache: /tmp/tgrun-bob-bdf82fd0)

# Running again as alice reuses her cache
$ USER=alice tgrun demo.mp --scope=3
[INFO] Generated 1 traces -> output/demo.json (cache: /tmp/tgrun-alice-bdf82fd0)  # SAME DIR!
```

This means re-running `tgrun demo.mp --scope=3` multiple times will reuse cached results, making subsequent runs nearly instant. The cache directory persists across sessions until manually cleaned or system reboot (TMPDIR cleanup).

### Cache Cleanup with `-k` / `--clean`

Use the `-k` or `--clean` flag to delete the cache directory after each run, regardless of success or failure:

```bash
# Run and automatically clean cache afterward
$ tgrun demo.mp --scope=3 -k
[INFO] Generated 1 traces -> output/demo.json (cache: /tmp/tgrun-0-bdf82fd0)
[INFO] Cleaned cache directory: /tmp/tgrun-0-bdf82fd0

# Same with long form
$ tgrun demo.mp --scope=3 --clean
```

This is useful when you want to avoid disk space accumulation or ensure fresh results on every run. The flag works with all commands (`run`, CUDA generation via `-o`/`--build-only`, `parse`).

### Error Reporting with Context

`tgrun` provides detailed error messages when parsing fails, including the exact line and column where the error occurred, along with surrounding context (5 lines of code). For example:

```bash
$ tgrun bad.mp --scope=3
=== Parse Error at line 4, column 18 ===
line 4, column 18: expected ':' after rule name

--- Context (showing lines 2-6 ---
      2 | 
      3 | // Missing colon after rule name - should trigger parse error
>>>   4 | ROOT BadRuleName (* send *;
    |                      ^
      5 | COORDINATE $x: send FROM Sender,
      6 |            $y: receive FROM Receiver

⚠️  Possible bracket mismatch detected!
   Check that all opening brackets have matching closing brackets.
   ⚠️  Unmatched opening '(' found on this line (4)
     The closing ')' is missing or on a different line.
```

The error message shows:
- **Line and column** of the parse failure
- **Error description** from the parser
- **Context lines** with `>>>` marking the offending line
- **Column pointer** (`^`) showing exact position in the line
- **Bracket mismatch warnings** if applicable (e.g., unclosed parentheses)

For multi-line bracket mismatches, tgrun shows the matching opening bracket location:

```bash
$ tgrun multiline.mp --scope=1
=== Parse Error at line 5, column 13 ===
line 5, column 13: expected ':' after rule name

--- Context (showing lines 3-7 ---
      3 | // Opening paren here, never closed
      4 | (
>>>   5 | ROOT Sender send;
    |                 ^
      6 | COORDINATE $x: send FROM Sender,
      7 |            $y: receive FROM Receiver

⚠️  Possible bracket mismatch detected!
   Check that all opening brackets have matching closing brackets.
   Opening '(' found on line 4:
       3 | // Opening paren here, never closed
     >>>  4 | (
       5 | ROOT Sender send;
       6 | COORDINATE $x: send FROM Sender,
       7 |            $y: receive FROM Receiver
   Closing ')' on line 5:
     >>>  5 | ROOT Sender send;
```

This makes it easy to identify and fix syntax errors in MP files.
