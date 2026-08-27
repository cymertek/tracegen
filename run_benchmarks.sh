#!/bin/bash

# Comprehensive benchmark comparing tgeval performance across examples
# Tests both execution time and memory usage

set -e

EXAMPLES=(
    "/workdir/old/trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp"
    "/workdir/old/trace-generator/Firebird_Pre_loaded_examples/Example02_Data_flow.mp"
    "/workdir/old/trace-generator/Firebird_Pre_loaded_examples/Example03_ATM_withdrawal.mp"
    "/workdir/old/trace-generator/Firebird_Pre_loaded_examples/Example08_Operational_Process.mp"
)

echo "=== tgeval Benchmark Results ==="
echo ""
printf "%-50s | %-12s | %-12s | %-10s\n" "File" "Scope" "Time (s)" "Traces"
echo "-----------------------------------------------------------------------------------"

for example in "${EXAMPLES[@]}"; do
    filename=$(basename "$example")

    # Test with scope 1
    result=$(./bench "$example" 1 2>/dev/null | grep -E "File:|Scope:|Traces generated:|Execution time:")
    file=$(echo "$result" | grep "^File:" | awk '{print $2}')
    scope=$(echo "$result" | grep "^Scope:" | awk '{print $2}')
    traces=$(echo "$result" | grep "^Traces generated:" | awk '{print $3}')
    time=$(echo "$result" | grep "^Execution time:" | awk '{print $3}')

    printf "%-50s | %-12s | %-12s | %-10s\n" "$filename" "$scope" "$time" "$traces"
done

echo ""
echo "=== Memory Usage Summary ==="
echo "(Measured via runtime.MemStats TotalAlloc)"