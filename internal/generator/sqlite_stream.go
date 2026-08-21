// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"encoding/json"
	"fmt"

	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

// GenerateTracesToSQLite streams trace generation directly to SQLite store,
// avoiding memory accumulation while maintaining deduplication and pretty-printed output.
func (g *CPUGenerator) GenerateTracesToSQLite(schema *parser.SchemaNode, scope int, dbStore *store.SQLiteStore) error {
	// Expand each root rule into all possible trace paths.
	rootExps := make([]rootExpansion, 0, len(schema.Rules))
	for _, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		expansion := g.expandRule(&rule, scope)
		rootExps = append(rootExps, expansion)
	}

	totalInserted := 0

	// For each coordinate block with threads, combine root expansions and stream to SQLite.
	for _, coord := range schema.Coordinates {
		if coord == nil || len(coord.Threads) == 0 {
			continue
		}
		coordTraces := g.combineWithCoordinate(rootExps, coord)

		// Deduplicate per-coordinate (matches current behavior).
		dedupedTraces := deduplicateByCombinedEvents(coordTraces)

		for _, trace := range dedupedTraces {
			if err := writeTraceToStore(dbStore, trace); err != nil {
				return fmt.Errorf("writing trace to store: %w", err)
			}
			totalInserted++
		}
	}

	// Include standalone root traces if no coordinate traces were produced.
	if totalInserted == 0 {
		for _, re := range rootExps {
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
