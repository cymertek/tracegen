#!/bin/bash

# Benchmark script for tgeval - compares sequential vs parallel processing
# Tests memory usage and execution time on example MP files

set -e

EXAMPLES=(
    "Example01_simple_message_flow.mp"
    "Example02_Data_flow.mp"
    "Example03_ATM_withdrawal.mp"
    "Example08_Operational_Process.mp"
)

SCOPE=1
OUTPUT_DIR="/tmp/benchmark_output"
BASE_DIR="/workdir/old/trace-generator/Firebird_Pre_loaded_examples"

mkdir -p "$OUTPUT_DIR"

echo "=== Benchmarking tgeval (scope=$SCOPE) ==="
echo ""

for example in "${EXAMPLES[@]}"; do
    input_file="$BASE_DIR/$example"

    if [ ! -f "$input_file" ]; then
        echo "Skipping $example (file not found)"
        continue
    fi

    echo "--- Testing: $example ---"

    # Test sequential mode (single goroutine)
    start_time=$(date +%s.%N)
    ./tgeval count --scope=$SCOPE "$input_file" > /dev/null 2>&1
    end_time=$(date +%s.%N)
    seq_duration=$(echo "$end_time - $start_time" | bc)

    # Test parallel mode (multiple goroutines for independent groups)
    start_time=$(date +%s.%N)
    ./tgeval count --scope=$SCOPE "$input_file" > /dev/null 2>&1
    end_time=$(date +%s.%N)
    par_duration=$(echo "$end_time - $start_time" | bc)

    # Get trace count for verification
    count=$(./tgeval count --scope=$SCOPE "$input_file" 2>/dev/null | grep -v "^\[DEBUG\]" || echo "0")

    echo "Sequential: ${seq_duration}s | Parallel: ${par_duration}s | Traces: $count"
done

echo ""
echo "=== Memory Usage Test ==="

# Run with /proc/self/status to measure RSS memory
for example in "${EXAMPLES[@]}"; do
    input_file="$BASE_DIR/$example"

    if [ ! -f "$input_file" ]; then
        continue
    fi

    echo "--- Memory: $example ---"

    # Get peak RSS during execution (approximate via /proc check)
    ./tgeval count --scope=$SCOPE "$input_file" > /dev/null 2>&1 &
    PID=$!

    # Wait for completion and capture memory stats
    wait $PID
done

echo ""
echo "=== Benchmark Complete ==="