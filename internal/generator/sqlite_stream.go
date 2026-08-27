// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"encoding/json"
	"fmt"
	"runtime"
	

	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

// GenerateTracesToSQLite streams trace generation directly to SQLite store,
// avoiding memory accumulation while maintaining deduplication and pretty-printed output.
func (g *CPUGenerator) GenerateTracesToSQLite(schema *parser.SchemaNode, scope int, dbStore *store.SQLiteStore) error {
	// Expand each root rule into all possible trace paths - store as field to avoid closure copies
	g.rootExps = make([]rootExpansion, 0, len(schema.Coordinates))
	for _, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		expansion := g.expandRule(&rule, scope)
		g.rootExps = append(g.rootExps, expansion)
	}

	totalInserted := int64(0)

	// Process coordinates sequentially to minimize memory usage
	for _, coord := range schema.Coordinates {
		if coord == nil || len(coord.Threads) == 0 {
			continue
		}

		fmt.Printf("[DEBUG] Processing coordinate with %d threads:\n", len(coord.Threads))
		for i, thread := range coord.Threads {
			fmt.Printf("  Thread %d: EventName=%q From=%v\n", i, thread.EventName, thread.From)
		}

		// Stream combinations directly to SQLite without accumulating in memory
		count, err := g.processCoordinateStreaming(dbStore, coord)
		if err != nil {
			return fmt.Errorf("processing coordinate: %w", err)
		}
		totalInserted += int64(count)

		// Force garbage collection after each coordinate to release intermediate slices
		runtime.GC()
	}

	// Include standalone root traces if no coordinate traces were produced.
	if totalInserted == 0 {
		for _, re := range g.rootExps {
			for _, p := range re.paths {
				trace := TraceSegment{
					MarkStatus:   "U",
					Probability:  p.prob,
					Events:       p.events,
					FollowsPairs: [][]int{},
					InPairs:      [][]int{},
					VViews:       []any{},
				}
				if err := writeTraceToStore(dbStore, trace); err != nil {
					return fmt.Errorf("writing root trace to store: %w", err)
				}
				totalInserted++
			}
		}
	}

	return nil
}

// processCoordinateStreaming processes a coordinate block and streams results directly to SQLite
// without accumulating all combinations in memory. This is critical for large scope values.
func (g *CPUGenerator) processCoordinateStreaming(dbStore *store.SQLiteStore, coord *parser.CoordinateNode) (int, error) {
	if coord == nil || len(coord.Threads) == 0 {
		return 0, nil
	}

	numThreads := len(coord.Threads)
	options := make([][]tracePath, numThreads)
	for tIdx, thread := range coord.Threads {
		if thread.EventName != "" {
			options[tIdx] = []tracePath{{
				events: []EventTuple{{Name: thread.EventName, Type: "A", Position: 1}},
				marked: false,
				prob:   1.0,
			}}
		} else if thread.From != nil {
			for _, re := range g.rootExps {
				if re.ruleName == thread.From.Name {
					if len(re.paths) > 0 {
						options[tIdx] = append(options[tIdx], re.paths...)
					} else {
						options[tIdx] = []tracePath{{}}
					}
					break
				}
			}
		}

		if options[tIdx] == nil {
			options[tIdx] = []tracePath{{}}
		}
	}

	totalConfigs := 1
	for _, opts := range options {
		totalConfigs *= len(opts)
	}
	if totalConfigs == 0 || numThreads <= 0 {
		return 0, nil
	}

	allNull := true
	for tIdx := 0; tIdx < numThreads; tIdx++ {
		if len(options[tIdx]) != 1 || len(options[tIdx][0].events) > 0 {
			allNull = false
			break
		}
	}
	if allNull {
		return 0, nil
	}

	count := 0
	// Process each combination one at a time and write directly to SQLite
	for c := 0; c < totalConfigs; c++ {
		idxs := decodeMixedRadix(c, options)
		rawEvents := collectThreadEvents(options, idxs, numThreads)
		events := mergeThreadEvents(rawEvents, coord.Threads)

		trace := TraceSegment{
			MarkStatus:   "U",
			Probability:  computeThreadProbability(options, idxs),
			Events:       events,
			FollowsPairs: assignCoordFollows(events, coord),
			InPairs:      [][]int{},
			VViews:       []any{},
		}

		if err := writeTraceToStore(dbStore, trace); err != nil {
			return count, fmt.Errorf("writing trace to store: %w", err)
		}
		count++

		// Release memory for this iteration
		trace = TraceSegment{}
		events = nil
		rawEvents = nil
		idxs = nil
	}

	return count, nil
}

// writeTraceToStore converts a TraceSegment to a store.TraceRecord and inserts/updates it in SQLite.
func writeTraceToStore(dbStore *store.SQLiteStore, trace TraceSegment) error {
	events := make([]interface{}, len(trace.Events))
	for j, evt := range trace.Events {
		events[j] = []interface{}{evt.Name, evt.Type, evt.Position, evt.RuleIdx}
	}

	key := generateTraceKey(events)

	record := store.TraceRecord{
		Key:          key,
		MarkStatus:   trace.MarkStatus,
		Probability:  trace.Probability,
		Events:       events,
		FollowsPairs: serializePairs(trace.FollowsPairs),
		InPairs:      serializeInPairs(trace.InPairs),
	}

	return dbStore.InsertOrIncrement(key, record)
}

// generateTraceKey creates a deterministic key for trace deduplication using FNV-1a hash.
func generateTraceKey(events []interface{}) string {
	data, _ := json.Marshal(events)
	var h uint32 = 2166136261 // FNV offset basis
	for _, b := range data {
		h ^= uint32(b)
		h *= 16777619 // FNV prime
	}
	return fmt.Sprintf("%08x", h)
}

// serializePairs converts follows pairs to JSON-serializable format.
func serializePairs(pairs [][]int) interface{} {
	result := make([][]interface{}, len(pairs))
	for i, p := range pairs {
		if len(p) >= 2 {
			result[i] = []interface{}{p[0], p[1]}
		} else if len(p) == 1 {
			result[i] = []interface{}{p[0]}
		} else {
			result[i] = []interface{}{}
		}
	}
	return result
}

// serializeInPairs converts in-pairs to JSON-serializable format.
func serializeInPairs(pairs [][]int) interface{} {
	if pairs == nil {
		pairs = [][]int{}
	}
	result := make([][]interface{}, len(pairs))
	for i, p := range pairs {
		if len(p) >= 2 {
			result[i] = []interface{}{p[0], p[1]}
		} else if len(p) == 1 {
			result[i] = []interface{}{p[0]}
		} else {
			result[i] = []interface{}{}
		}
	}
	return result
}
