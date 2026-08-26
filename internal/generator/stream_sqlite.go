// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"encoding/json"
	"fmt"
	"runtime"

	"github.com/cymertek/tracegen/internal/store"
)

const gcBatchSize = 1000 // run GC hint every N traces to bound memory

// StreamTracesToWriter reads traces from SQLite cursor and writes them as JSON
// directly to the StreamWriter — no in-memory accumulation of all traces.
// If progressCallback is non-nil, it will be called after each trace with the current count.
func StreamTracesToWriter(dbStore *store.SQLiteStore, sw *StreamWriter, progressCallback func(int64)) error {
	rows, err := dbStore.QueryAllTracesCursor()
	if err != nil {
		return fmt.Errorf("opening trace cursor: %w", err)
	}
	defer rows.Close()

	// Write JSON header.
	if err := sw.WriteHeader(); err != nil {
		return fmt.Errorf("writing header: %w", err)
	}

	var traceCount int64

	for rows.Next() {

		var r store.TraceRecord
		var eventsJSON, followsPairsJSON, inPairsJSON, udrsJSON, viewsJSON string

		if scanErr := rows.Scan(&r.Key, &r.MarkStatus, &r.Probability, &eventsJSON, &followsPairsJSON, &inPairsJSON, &udrsJSON, &viewsJSON, &r.Count); scanErr != nil {
			return fmt.Errorf("scanning trace row: %w", scanErr)
		}

		var eventsAny any
		if err := json.Unmarshal([]byte(eventsJSON), &eventsAny); err != nil {
			eventsAny = []any{} // fallback empty events
		}

		var followsAny any
		if err := json.Unmarshal([]byte(followsPairsJSON), &followsAny); err != nil {
			followsAny = nil
		}

		var inAny any
		if err := json.Unmarshal([]byte(inPairsJSON), &inAny); err != nil {
			inAny = nil
		}

		traceArray := []any{
			r.MarkStatus,
			r.Probability,
			eventsAny,
			followsAny,
			inAny,
			map[string]any{"VIEWS": []any{}},
			float64(r.Count),
		}

		if !sw.IncrementCount() {
			return fmt.Errorf("trace limit reached (%d traces)", sw.maxTraces)
		}

		traceJSON, err := json.Marshal(traceArray)
		if err != nil {
			return fmt.Errorf("marshaling trace: %w", err)
		}

		sw.mu.Lock()
		if !sw.first {
			fmt.Fprint(sw.writer, ",")
		}
		sw.first = false // mark as written after header
		fmt.Fprintf(sw.writer, "%s", string(traceJSON))
		sw.mu.Unlock()

		traceCount++
		if progressCallback != nil {
			progressCallback(traceCount)
		}
		if traceCount%gcBatchSize == 0 {
			runtime.GC() // release intermediate allocations periodically
		}
	}

	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterating trace cursor: %w", err)
	}

	return sw.WriteFooter()
}

// StreamTracesForSummary iterates traces from SQLite and calls callback per row,
// computing summary statistics incrementally without loading all records into memory.
func StreamTracesForSummary(dbStore *store.SQLiteStore, callback func(record store.TraceRecord) error) error {
	rows, err := dbStore.QueryAllTracesCursor()
	if err != nil {
		return fmt.Errorf("opening trace cursor: %w", err)
	}
	defer rows.Close()

	var traceCount int64

	for rows.Next() {
		var r store.TraceRecord
		var eventsJSON, followsPairsJSON, inPairsJSON, udrsJSON, viewsJSON string

		if scanErr := rows.Scan(&r.Key, &r.MarkStatus, &r.Probability, &eventsJSON, &followsPairsJSON, &inPairsJSON, &udrsJSON, &viewsJSON, &r.Count); scanErr != nil {
			return fmt.Errorf("scanning trace row: %w", scanErr)
		}

		if err := callback(r); err != nil {
			return fmt.Errorf("summary callback error at trace %d: %w", traceCount, err)
		}

		traceCount++
		if traceCount%gcBatchSize == 0 {
			runtime.GC() // release intermediate allocations periodically
		}
	}

	return rows.Err()
}
