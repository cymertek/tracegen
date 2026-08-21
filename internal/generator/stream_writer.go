// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"encoding/json"
	"fmt"
	"io"
	"sync"
)

// StreamWriter writes trace segments to JSON output incrementally,
// avoiding memory explosion from accumulating all traces at once.
type StreamWriter struct {
	writer   io.Writer
	mu       sync.Mutex
	first    bool
	count    int64
	maxTraces int64 // -1 means unlimited
}

// NewStreamWriter creates a new streaming JSON writer.
func NewStreamWriter(w io.Writer, maxTraces int64) *StreamWriter {
	if maxTraces == 0 {
		maxTraces = 100_000 // default limit to prevent runaway memory usage
	}
	return &StreamWriter{
		writer:    w,
		first:     true,
		maxTraces: maxTraces,
	}
}

// WriteHeader writes the JSON opening: {"traces":[
func (sw *StreamWriter) WriteHeader() error {
	sw.mu.Lock()
	defer sw.mu.Unlock()
	_, err := fmt.Fprintf(sw.writer, "{\"traces\":[")
	return err
}

// WriteTrace writes a single trace segment as JSON.
func (sw *StreamWriter) WriteTrace(seg TraceSegment) error {
	sw.mu.Lock()
	defer sw.mu.Unlock()

	if sw.first {
		sw.first = false
	} else {
		_, err := fmt.Fprint(sw.writer, ",")
		if err != nil {
			return err
		}
	}

	events := make([][]any, len(seg.Events))
	for j, evt := range seg.Events {
		events[j] = []any{evt.Name, evt.Type, evt.Position, evt.RuleIdx, evt.Segment}
	}

	traceJSON := []any{
		seg.MarkStatus,
		seg.Probability,
		events,
		seg.FollowsPairs,
		seg.InPairs,
		map[string]any{"VIEWS": seg.VViews},
	}

	data, err := json.Marshal(traceJSON)
	if err != nil {
		return fmt.Errorf("error marshaling trace: %w", err)
	}

	_, err = sw.writer.Write(data)
	return err
}

// WriteFooter writes the JSON closing: ]}\n
func (sw *StreamWriter) WriteFooter() error {
	sw.mu.Lock()
	defer sw.mu.Unlock()
	_, err := fmt.Fprintf(sw.writer, "]\n}\n")
	return err
}

// IncrementCount increments the trace counter and returns whether to continue.
// Returns false if maxTraces has been reached.
func (sw *StreamWriter) IncrementCount() bool {
	sw.mu.Lock()
	defer sw.mu.Unlock()
	sw.count++
	if sw.maxTraces > 0 && sw.count >= sw.maxTraces {
		return false
	}
	return true
}

// Count returns the current trace count.
func (sw *StreamWriter) Count() int64 {
	sw.mu.Lock()
	defer sw.mu.Unlock()
	return sw.count
}
