# Build Fix: tgserve Command Not Found

## Problem
The Makefile referenced `cmd/tgserve/` directory, but the actual command was located at `cmd/server/`. This caused build failures with error:
```
stat /home/schou/git/monterey-phoenix/tracegen/cmd/tgserve: directory not found
```

## Solution
Created a symbolic link from `cmd/tgserve` → `cmd/server`:
```bash
ln -s cmd/server cmd/tgserve
```

This allows the Makefile to work without modification while keeping the codebase clean.

## Verification
```bash
$ go build -buildvcs=false -o bin/tgserve ./cmd/tgserve/
✓ tgserve built successfully
```

## Alternative Solutions Considered
1. **Update Makefile**: Change all references from `./cmd/$$bin/` to use correct paths for each binary
2. **Rename directory**: Rename `cmd/server/` to `cmd/tgserve/` (would require updating imports)
3. **Create symlink** (chosen): Minimal change, preserves existing structure

## Files Changed
- `/workdir/tracegen/cmd/tgserve` → symlink to `/workdir/tracegen/cmd/server`

## Next Steps
Commit this fix with git using your cymertek identity:
```bash
cd /workdir/tracegen
git add cmd/tgserve
git commit -m "fix: create tgserve symlink for build compatibility" --author="cymertek <cymertek@users.noreply.github.com>"
```
