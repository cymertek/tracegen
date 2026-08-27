# Progress Reporter Feature

## Overview
Added a `--progress` flag to `tgeval eval` that outputs progress updates as JSON-formatted lines prefixed with `# [PROGRESS] `. This allows GUIs and other tools to easily parse and display trace generation progress.

## Usage
```bash
./tgeval eval --progress <file.mp>
```

## Output Format
Each progress update is printed every 2 seconds in the format:
```
# [PROGRESS] {"seconds": X.X, "done": N, "total": M, "perSecond": X.X, "percent": XX.X}
```

### Fields
- `seconds`: Elapsed time since start (float)
- `done`: Number of traces generated so far (int)
- `total`: Total number of unique traces expected (int)
- `perSecond`: Current processing rate using moving average over 5 samples (float)
- `percent`: Completion percentage (float, 0-100)

### When total is unknown
If the total trace count is not known upfront:
```
# [PROGRESS] {"seconds": X.X, "done": N}
```

## Implementation Details

### Moving Average Rate Calculation
The `perSecond` rate uses a moving average over the last 5 samples to smooth out fluctuations:
- Maintains a tape of 5 (count, timestamp) pairs
- Calculates delta between current and previous sample
- Divides by time difference, capped at 10 seconds minimum

### Memory Efficiency
Progress reporter runs in a background goroutine with minimal memory footprint:
- Only stores 5 samples in the tape history
- Uses atomic counters for thread-safe updates
- Does not accumulate trace data in memory

## GUI Integration Example (Python)
```python
import subprocess
import json
import sys

def parse_progress(line):
    if line.startswith("# [PROGRESS] "):
        try:
            return json.loads(line.split(" ", 1)[1])
        except json.JSONDecodeError:
            pass
    return None

# Run tgeval with progress output
proc = subprocess.Popen(
    ["./tgeval", "eval", "--progress", "model.mp"],
    stderr=subprocess.PIPE,
    text=True
)

for line in proc.stderr:
    progress = parse_progress(line.strip())
    if progress:
        print(f"Processing: {progress['percent']:.1f}% ({progress['done']}/{progress['total']})")
```

## Testing
Run the test script to verify functionality:
```bash
rm -rf .tgrun_cache
timeout 10 ./tgeval eval --progress preloaded-examples/original_examples/Example03_ATM_withdrawal.mp > /dev/null 2>/tmp/stderr_progress.txt
cat /tmp/stderr_progress.txt | grep "PROGRESS" | awk '{print $NF}' | python3 -c "import sys,json; [json.loads(line) for line in sys.stdin]; print('Valid JSON')"
```

## Files Modified
- `cmd/tgeval/main.go`: Added progress flag and startProgressReporter function
- `internal/generator/stream_sqlite.go`: Updated StreamTracesToWriter to accept callback

## Related Features
- SQLite-backed streaming output (memory-bounded)
- Cursor-based query for efficient JSON serialization
- GC hints between coordinate blocks
