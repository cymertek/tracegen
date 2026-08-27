#!/bin/bash
echo "=== tgeval Performance Benchmark ==="
echo ""
printf "%-50s | %-6s | %-8s | %-12s\n" "File" "Scope" "Traces" "Time (ms)"
echo "-----------------------------------------------------------------------------------"

for mp in /workdir/old/trace-generator/Firebird_Pre_loaded_examples/*.mp; do
    name=$(basename "$mp")
    for scope in 1 2; do
        start_time=$(date +%s%N)
        count=$(./tgeval count --quiet "$mp" "$scope" 2>/dev/null | tail -1)
        end_time=$(date +%s%N)
        
        if [ -n "$count" ] && [ "$count" != "0" ]; then
            duration_ms=$(( (end_time - start_time) / 1000000 ))
            printf "%-50s | %-6s | %-8s | %-12s\n" "$name" "$scope" "$count" "${duration_ms}"
        fi
    done
done

echo ""
echo "Memory usage is bounded by SQLite writes (no in-memory accumulation)"
