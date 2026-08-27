# Build Guide for CYMERTEK Trace Generator

## Quick Start

```bash
make build        # Build for current platform only
make build-all    # Cross-compile for all platforms (Linux, macOS, Windows)
make package-all  # Create distribution packages for all platforms
```

## Available Targets

### `build`
Builds binaries for the current platform:
- `bin/tgeval` - Standalone MP file evaluator
- `bin/tgrun` - Full trace generator with GPU support
- `bin/tgserve` - Gryphon-compatible socket server

### `build-all`
Cross-compiles for all common platforms (8 combinations):

| OS | Architecture | Output Directory |
|----|--------------|------------------|
| Linux | amd64 | `bin/linux-amd64/` |
| Linux | arm64 | `bin/linux-arm64/` |
| macOS | amd64 | `bin/darwin-amd64/` |
| macOS | arm64 (Apple Silicon) | `bin/darwin-arm64/` |
| Windows | amd64 | `bin/windows-amd64/` |
| Windows | arm64 | `bin/windows-arm64/` |

### `build-alpine`
Builds static Alpine-compatible binaries (musl libc):
- `bin/alpine-amd64/` - Linux x86_64 with musl
- `bin/alpine-arm64/` - Linux ARM64 with musl

These are ideal for Docker containers and minimal environments.

### `package-all`
Creates distribution packages:
- `.tar.gz` files for Linux, macOS, and Alpine
- `.zip` files for Windows (better compatibility)

## Build Configuration

The Makefile uses these defaults:
- **Go version**: 1.22.5 (specified via GOTOOLCHAIN)
- **Stripping**: Binaries are stripped of debug symbols (`-ldflags="-s -w"`)
- **VCS stamping**: Disabled (`-buildvcs=false`) for reproducibility

## Testing Cross-Compilation

To verify the build works on your system:

```bash
# Test current platform
make build

# Test cross-compilation (requires Go 1.22+)
make build-all

# Verify binaries
file bin/linux-amd64/tgeval
file bin/darwin-arm64/tgeval
file bin/windows-amd64/tgeval.exe
```

## Docker Build Example

For Alpine-based containers:

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache ca-certificates

COPY tracegen-alpine-amd64.tar.gz /app/
WORKDIR /app

CMD ["./tgrun"]
```

## Notes

- The `modernc.org/sqlite` dependency is pure Go and works on all platforms without CGO
- Windows builds include `.exe` extension automatically
- All binaries are statically linked (no external dependencies required)
