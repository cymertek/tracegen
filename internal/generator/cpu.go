// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package generator implements CPU-based trace generation for MP programs.
package generator

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"

	"github.com/alphadose/haxmap"
	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

// TraceSegment represents a single generated trace segment matching C++ output format exactly.
type TraceSegment struct {
	MarkStatus   string
	Probability  float64
	Events       []EventTuple
	FollowsPairs [][]int
	InPairs      [][]int
	VViews       []any
}

// EventTuple represents an event in the trace output format: [Name, Type, Position, RuleIdx, Segment].
type EventTuple struct {
	Name     string `json:"-"`
	Type     string `json:"-"` // "A" for atomic, "R" for rule
	Position int    `json:"-"`
	RuleIdx  int    `json:"-"`
	Segment  int    `json:"-"`
}

// CPUGenerator generates traces from MP schemas using CPU execution.
type CPUGenerator struct {
	rootExps []rootExpansion // Store root expansions as field
	rng *rand.Rand
}

// NewCPUGenerator creates a new CPU trace generator with the given seed.
func NewCPUGenerator(seed int64) *CPUGenerator {
	return &CPUGenerator{
		rng: rand.New(rand.NewSource(seed)),
	}
}

const parallelCombineThreshold = 32 // minimum root combinations to trigger parallel mode

// --- Internal types for cartesian product expansion ---

// tracePath represents one possible event sequence from a single root rule.
type tracePath struct {
	events []EventTuple
	marked bool    // true if any event has MarkStatus "M"
	prob   float64 // probability of this path
}

// rootExpansion holds all possible trace paths for a single root rule.
type rootExpansion struct {
	ruleName string
	paths    []tracePath
}

func (g *CPUGenerator) GenerateTraces(schema *parser.SchemaNode, scope int) ([]TraceSegment, error) {
	var traces []TraceSegment

	// Expand each root rule into all possible trace paths.
	rootExps := make([]rootExpansion, 0, len(schema.Rules))
	for _, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		expansion := g.expandRule(&rule, scope)
		rootExps = append(rootExps, expansion)
	}

	// For each coordinate block with threads, combine root expansions.
	for _, coord := range schema.Coordinates {
		if coord == nil || len(coord.Threads) == 0 {
			continue
		}
		coordTraces := g.combineWithCoordinate(rootExps, coord)
		traces = append(traces, coordTraces...)
	}

	// Deduplicate traces by combined event sequence (matching rigsc behavior).
	// Multiple coordinates can produce identical combined events.
	dedupedTraces := deduplicateByCombinedEvents(traces)

	// Use the deduplicated traces.
	traces = dedupedTraces

	// Also include standalone root traces when coordinates produced only null-path traces
	// (i.e., zero-event coordinate traces from roots with empty expansions).
	if len(traces) == 0 || allTracesEmpty(traces) {
		for _, re := range rootExps {
			for _, p := range re.paths {
				traces = append(traces, TraceSegment{
					MarkStatus:   "U",
					Probability:  p.prob,
					Events:       p.events,
					FollowsPairs: [][]int{},
					InPairs:      [][]int{},
					VViews:       []any{},
				})
			}
		}
	}

	return traces, nil
}

// GenerateTracesStreaming generates trace segments and writes them to a streaming writer.
// This avoids memory explosion by not accumulating all traces in memory at once.
func (g *CPUGenerator) GenerateTracesStreaming(schema *parser.SchemaNode, scope int, sw *StreamWriter) error {
	// Expand each root rule into all possible trace paths.
	rootExps := make([]rootExpansion, 0, len(schema.Rules))
	for _, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		expansion := g.expandRule(&rule, scope)
		rootExps = append(rootExps, expansion)
	}

	// Write JSON header.
	if err := sw.WriteHeader(); err != nil {
		return fmt.Errorf("failed to write header: %w", err)
	}

	// For each coordinate block with threads, combine root expansions and stream output.
	for _, coord := range schema.Coordinates {
		if coord == nil || len(coord.Threads) == 0 {
			continue
		}
		coordTraces := g.combineWithCoordinate(rootExps, coord)

		// Deduplicate before streaming.
		dedupedTraces := deduplicateByCombinedEvents(coordTraces)

		for _, trace := range dedupedTraces {
			if !sw.IncrementCount() {
				return fmt.Errorf("trace limit reached (%d traces)", sw.maxTraces)
			}
			if err := sw.WriteTrace(trace); err != nil {
				return fmt.Errorf("failed to write trace: %w", err)
			}
		}
	}

	// Include standalone root traces if no coordinate traces were produced.
	if sw.Count() == 0 {
		for _, re := range rootExps {
			for _, p := range re.paths {
				if !sw.IncrementCount() {
					return fmt.Errorf("trace limit reached (%d traces)", sw.maxTraces)
				}
				trace := TraceSegment{
					MarkStatus:   "U",
					Probability:  p.prob,
					Events:       p.events,
					FollowsPairs: [][]int{},
					InPairs:      [][]int{},
					VViews:       []any{},
				}
				if err := sw.WriteTrace(trace); err != nil {
					return fmt.Errorf("failed to write trace: %w", err)
				}
			}
		}
	}

	// Write JSON footer.
	return sw.WriteFooter()
}

// expandRule expands a root rule into all possible trace paths respecting scope.
func (g *CPUGenerator) expandRule(rule *parser.RuleNode, scope int) rootExpansion {
	exp := rootExpansion{ruleName: rule.Name}

	for _, pattern := range rule.PatternList {
		switch p := pattern.(type) {
		case *parser.AtomicEventNode:
			exp.paths = append(exp.paths, tracePath{
				events: []EventTuple{{Name: p.Name, Type: "A", Position: 1}},
				marked: false,
				prob:   g.eventProbability(p),
			})

		case *parser.AltGroupNode:
			for i, alt := range p.Alternatives {
				for _, pat := range alt.PatternList {
					if ae, ok := pat.(*parser.AtomicEventNode); ok {
						trace := g.makeAtomicTrace(ae.Name, "A", 1, i)
						exp.paths = append(exp.paths, tracePath{
							events: []EventTuple{trace.Events[0]},
							marked: false,
							prob:   g.eventProbability(ae),
						})
					}
				}
			}

		case *parser.ListPatternNode:
			items := p.Items
			if len(items) == 0 {
				continue
			}

			reps := max(1, scope)

			// Generate all possible event sequences for this ListPatternNode.
			allSequences := g.collectListSequences(items, nil)

			for r := 0; r < reps; r++ {
				for _, seq := range allSequences {
					events := make([]EventTuple, len(seq))
					copy(events, seq)
					for i := range events {
						events[i].Position = r*len(allSequences[0]) + i + 1
					}
					exp.paths = append(exp.paths, tracePath{
						events: events,
						marked: false,
						prob:   g.eventProbability(nil),
					})
				}
			}

		case *parser.ItPlusPatternNode:
			items := append([]parser.PatternUnitNode{p.Item}, p.PatternList...)
			if len(items) == 0 {
				continue
			}

			var seqEvents []EventTuple
			for _, item := range items {
				switch it := item.(type) {
				case *parser.AtomicEventNode:
					seqEvents = append(seqEvents, EventTuple{Name: it.Name, Type: "A", Position: len(seqEvents) + 1})
				default:
					continue
				}
			}

			if len(seqEvents) > 0 {
				reps := max(1, scope)
				for r := 0; r < reps; r++ {
					events := make([]EventTuple, len(seqEvents))
					copy(events, seqEvents)
					for i := range events {
						events[i].Position = r*len(seqEvents) + i + 1
					}
					exp.paths = append(exp.paths, tracePath{
						events: events,
						marked: false,
						prob:   1.0 / float64(reps),
					})
				}
			}

		case *parser.OptionalPatternNode:
			for _, pat := range p.PatternList {
				if ae, ok := pat.(*parser.AtomicEventNode); ok {
					exp.paths = append(exp.paths, tracePath{
						events: []EventTuple{{Name: ae.Name, Type: "A", Position: 1}},
						marked: false,
						prob:   g.eventProbability(ae),
					})
				}
			}
			exp.paths = append(exp.paths, tracePath{
				events: []EventTuple{},
				marked: false,
				prob:   1.0 - g.eventProbability(nil),
			})

		default:
			// Skip unsupported pattern types for now.
		}
	}

	return exp
}

// combineWithCoordinate combines root expansions with a single coordinate block's threads.
func (g *CPUGenerator) combineWithCoordinate(rootExps []rootExpansion, coord *parser.CoordinateNode) []TraceSegment {
	if coord == nil || len(coord.Threads) == 0 {
		return nil
	}

	numThreads := len(coord.Threads)
	options := make([][]tracePath, numThreads)
	for tIdx, thread := range coord.Threads {
		// Resolve each coordinate thread to its single atomic event (matching rigsc behavior).
		// The FROM clause identifies which root "owns" this thread for ordering purposes,
		// but the EventName is used directly as a single trace path.
		if thread.EventName != "" {
			options[tIdx] = []tracePath{{
				events: []EventTuple{{Name: thread.EventName, Type: "A", Position: 1}},
				marked: false,
				prob:   1.0,
			}}
		} else if thread.From != nil {
			// Fallback: find matching root and use its paths.
			for _, re := range rootExps {
				if re.ruleName == thread.From.Name {
					if len(re.paths) > 0 {
						options[tIdx] = append(options[tIdx], re.paths...)
					} else {
						options[tIdx] = []tracePath{{}} // null path if no expansions
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
		return nil
	}

	// Check if all threads have exactly one null path (zero events).
	// In that case, skip the coordinate trace and let fallback emit individual root traces.
	allNull := true
	for tIdx := 0; tIdx < numThreads; tIdx++ { //nolint:rangeint // need index value
		if len(options[tIdx]) != 1 || len(options[tIdx][0].events) > 0 {
			allNull = false
			break
		}
	}
	if allNull {
		return nil
	}

	var traces []TraceSegment
	isParallel := len(rootExps) > 1 && totalConfigs >= parallelCombineThreshold
	if isParallel {
		traces = g.combineWithCoordinateParallel(options, coord)
	} else {
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

			traces = append(traces, trace)
		}
	}

	return traces
}

// combineWithCoordinateParallel generates trace segments using multiple goroutines with deduplication via haxmap.
func (g *CPUGenerator) combineWithCoordinateParallel(options [][]tracePath, coord *parser.CoordinateNode) []TraceSegment {
	numWorkers := runtime.NumCPU()
	if numWorkers < 1 {
		numWorkers = 4
	}

	totalConfigs := 1
	for _, opts := range options {
		totalConfigs *= len(opts)
	}
	chunkSize := (totalConfigs + numWorkers - 1) / numWorkers

	// Check if all threads have exactly one null path (zero events).
	allNull := true
	for tIdx := 0; tIdx < len(options); tIdx++ {
		if len(options[tIdx]) != 1 || len(options[tIdx][0].events) > 0 {
			allNull = false
			break
		}
	}
	if allNull {
		return nil
	}

	sharedMap := haxmap.New[string, *traceGroup](uintptr(totalConfigs))
	var processedCount atomic.Int64

	var wg sync.WaitGroup
	wg.Add(numWorkers)

	for w := 0; w < numWorkers; w++ {
		go func(workerID int) {
			defer wg.Done()

			start := workerID * chunkSize
			end := start + chunkSize
			if end > totalConfigs {
				end = totalConfigs
			}

			for c := start; c < end && c < totalConfigs; c++ {
				idxs := decodeMixedRadix(c, options)
				sig := eventSignatureFromIndices(idxs, options)

				// Early GetOrCompute — only the winning goroutine computes events.
				grp, loaded := sharedMap.GetOrCompute(sig, func() *traceGroup {
					rawEvents := collectThreadEvents(options, idxs, len(options))
					events := mergeThreadEvents(rawEvents, coord.Threads)
					return &traceGroup{
						events:      events,
						probability: computeThreadProbability(options, idxs),
						marked:      false,
					}
				})

				if !loaded {
					processedCount.Add(1)
					// Store the config index for result collection (optional tracking).
					_ = grp // used when collecting results below
				}
			}
		}(w)
	}

	wg.Wait()

	var traces []TraceSegment
	for _, grp := range iterateMapValues(sharedMap) {
		traces = append(traces, TraceSegment{
			MarkStatus:   "U",
			Probability:  grp.probability,
			Events:       grp.events,
			FollowsPairs: assignCoordFollows(grp.events, coord),
			InPairs:      [][]int{},
			VViews:       []any{},
		})
	}

	return traces
}

// collectThreadEvents gathers events from selected trace paths for each thread.
func collectThreadEvents(options [][]tracePath, idxs []int, numThreads int) [][]EventTuple {
	events := make([][]EventTuple, numThreads)
	for i := 0; i < numThreads && i < len(idxs); i++ {
		if len(options[i]) > idxs[i] && idxs[i] >= 0 {
			events[i] = options[i][idxs[i]].events
		}
	}
	return events
}

// mergeThreadEvents merges thread events into a single ordered sequence.
func mergeThreadEvents(threadEvents [][]EventTuple, threads []parser.ThreadSelectionNode) []EventTuple {
	var merged []EventTuple
	pos := 1
	for _, rootEvents := range threadEvents {
		for _, evt := range rootEvents {
			merged = append(merged, EventTuple{
				Name:     evt.Name,
				Type:     "A",
				Position: pos,
				Segment:  len(merged),
			})
			pos++
		}
	}
	return merged
}

// computeThreadProbability computes the combined probability for a thread configuration.
func computeThreadProbability(options [][]tracePath, idxs []int) float64 {
	prob := 1.0
	for i, idx := range idxs {
		if len(options[i]) > idx && idx >= 0 {
			p := options[i][idx].prob
			if p > 0 {
				prob *= p
			}
		}
	}
	return prob
}

// assignCoordFollows generates follows pairs based on coordinate operations.
func assignCoordFollows(events []EventTuple, coord *parser.CoordinateNode) [][]int {
	if len(coord.Operations) == 0 {
		return [][]int{}
	}

	var pairs [][]int
	for i := 1; i < len(events); i++ {
		for _, op := range coord.Operations {
			if op.Type == "ADD" && op.RelationName == "PRECEDES" {
				pairs = append(pairs, []int{i + 1, i})
			}
		}
	}

	return pairs
}

// collectListSequences recursively collects all possible event sequences from a list of pattern units.
func (g *CPUGenerator) collectListSequences(items []parser.PatternUnitNode, prefix []EventTuple) [][]EventTuple {
	if len(items) == 0 {
		return [][]EventTuple{prefix}
	}

	item := items[0]
	var results [][]EventTuple

	switch it := item.(type) {
	case *parser.AtomicEventNode:
		newPrefix := make([]EventTuple, len(prefix)+1)
		copy(newPrefix, prefix)
		newPrefix[len(prefix)] = EventTuple{Name: it.Name, Type: "A"}
		results = g.collectListSequences(items[1:], newPrefix)

	case *parser.AltGroupNode:
		for _, alt := range it.Alternatives {
			var altEvents []EventTuple
			for _, pat := range alt.PatternList {
				if ae, ok := pat.(*parser.AtomicEventNode); ok {
					altEvents = append(altEvents, EventTuple{Name: ae.Name, Type: "A"})
				} else if ag, ok := pat.(*parser.AltGroupNode); ok {
					for _, subAlt := range ag.Alternatives {
						for _, sp := range subAlt.PatternList {
							if sae, ok := sp.(*parser.AtomicEventNode); ok {
								altEvents = append(altEvents, EventTuple{Name: sae.Name, Type: "A"})
							}
						}
					}
				}
			}

			newPrefix := make([]EventTuple, len(prefix)+len(altEvents))
			copy(newPrefix, prefix)
			for i, evt := range altEvents {
				newPrefix[len(prefix)+i] = evt
			}

			subResults := g.collectListSequences(items[1:], newPrefix)
			results = append(results, subResults...)
		}

	default:
		// Skip unsupported pattern types.
		return results
	}

	return results
}

func (g *CPUGenerator) eventProbability(p *parser.AtomicEventNode) float64 {
	if p == nil || p.Probability == nil {
		return 1.0
	}
	return p.Probability.Value
}

func (g *CPUGenerator) makeAtomicTrace(eventName, eventType string, position int, segIdx int) TraceSegment {
	trace := TraceSegment{
		MarkStatus:   "U",
		Probability:  1.0,
		Events:       []EventTuple{{Name: eventName, Type: eventType, Position: position, RuleIdx: 0, Segment: segIdx}},
		FollowsPairs: [][]int{},
		InPairs:      [][]int{},
		VViews:       []any{},
	}
	return trace
}

// --- Parallel cartesian product with haxmap ---

// traceGroup holds merged events and computed probability for deduplication.
type traceGroup struct {
	events      []EventTuple
	probability float64
	marked      bool
}

// decodeMixedRadix decodes a linear config index into per-root indices.
func decodeMixedRadix(config int, options [][]tracePath) []int {
	idxs := make([]int, len(options))
	rem := config
	for i := len(options) - 1; i >= 0; i-- {
		n := len(options[i])
		if n == 0 {
			n = 1
		}
		idxs[i] = rem % n
		rem /= n
	}
	return idxs
}

// eventSignatureFromIndices creates a fast signature for deduplication without computing full events.
func eventSignatureFromIndices(idxs []int, options [][]tracePath) string {
	var parts []string
	for i, idx := range idxs {
		if len(options[i]) > 0 && idx >= 0 && idx < len(options[i]) {
			events := options[i][idx].events
			for _, e := range events {
				parts = append(parts, fmt.Sprintf("%d:%s", i, e.Name))
			}
		}
	}
	return strings.Join(parts, "|")
}

// iterateMapValues iterates all values from a haxmap.
func iterateMapValues(m *haxmap.Map[string, *traceGroup]) []*traceGroup {
	var result []*traceGroup
	m.ForEach(func(_ string, v *traceGroup) bool {
		result = append(result, v)
		return true
	})
	return result
}

// MarshalToJSON converts trace segments to JSON format matching C++ output exactly.
func MarshalToJSON(segments []TraceSegment) (string, error) {
	jsonTraces := make([][]any, len(segments))
	for i, seg := range segments {
		events := make([][]any, len(seg.Events))
		for j, evt := range seg.Events {
			events[j] = []any{evt.Name, evt.Type, evt.Position, evt.RuleIdx, evt.Segment}
		}

		jsonTraces[i] = []any{
			seg.MarkStatus,
			seg.Probability,
			events,
			seg.FollowsPairs,
			seg.InPairs,
			map[string]any{"VIEWS": seg.VViews},
		}
	}

	var sb strings.Builder
	sb.WriteString("{\n  \"traces\":[\n\n")
	for i, trace := range jsonTraces {
		traceJSON, err := json.Marshal(trace)
		if err != nil {
			return "", fmt.Errorf("error marshaling trace %d: %w", i, err)
		}
		sb.WriteString(string(traceJSON))
		if i < len(jsonTraces)-1 {
			sb.WriteString(",\n\n")
		}
	}
	sb.WriteString("\n  ]\n}\n")

	return sb.String(), nil
}

// MarshalToJSONFromStore streams traces from SQLite store and produces pretty-printed JSON.
// Uses streaming cursor to avoid memory accumulation — writes one trace at a time instead of loading all into memory.
func MarshalToJSONFromStore(dbStore *store.SQLiteStore) (string, error) {
	rows, err := dbStore.QueryAllTracesCursor()
	if err != nil {
		return "", fmt.Errorf("opening trace cursor: %w", err)
	}
	defer rows.Close()

	var sb strings.Builder
	sb.WriteString("{\n  \"traces\":[\n\n")

	traceCount := 0
	for rows.Next() {
		var r store.TraceRecord
		var eventsJSON, followsPairsJSON, inPairsJSON, udrsJSON, viewsJSON string

		if scanErr := rows.Scan(&r.Key, &r.MarkStatus, &r.Probability, &eventsJSON, &followsPairsJSON, &inPairsJSON, &udrsJSON, &viewsJSON, &r.Count); scanErr != nil {
			return "", fmt.Errorf("scanning trace row: %w", scanErr)
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
			map[string]any{"VIEWS": []any{}}, // views handled separately if needed
			float64(r.Count),                 // count field showing how many times this pattern appeared
		}

		traceJSON, err := json.Marshal(traceArray)
		if err != nil {
			return "", fmt.Errorf("error marshaling trace %d: %w", traceCount, err)
		}

		sb.WriteString(string(traceJSON))
		if traceCount < 100000 { // add comma separator (will be fixed below if needed)
			sb.WriteString(",\n\n")
		}
		traceCount++
	}

	if err := rows.Err(); err != nil {
		return "", fmt.Errorf("iterating trace cursor: %w", err)
	}

	// Remove trailing comma if we wrote any traces
	jsonStr := sb.String()
	if traceCount > 0 {
		jsonStr = jsonStr[:len(jsonStr)-5] // remove ",\n\n" from end
	}
	jsonStr += "\n  ]\n}\n"

	return jsonStr, nil
}

// FormatTraceSegment formats a single trace segment for display.
func FormatTraceSegment(seg TraceSegment) string {
	var sb strings.Builder
	fmt.Fprintf(&sb, "MarkStatus: %s\n", seg.MarkStatus)
	fmt.Fprintf(&sb, "Probability: %.6f\n", seg.Probability)
	sb.WriteString("Events:\n")
	for _, event := range seg.Events {
		fmt.Fprintf(&sb, "  - %s (%s) at position %d\n", event.Name, event.Type, event.Position)
	}
	if len(seg.FollowsPairs) > 0 {
		sb.WriteString("Follows Pairs:\n")
		for _, pair := range seg.FollowsPairs {
			fmt.Fprintf(&sb, "  - [%d, %d]\n", pair[0], pair[1])
		}
	}
	if len(seg.InPairs) > 0 {
		sb.WriteString("In Pairs:\n")
		for _, pair := range seg.InPairs {
			fmt.Fprintf(&sb, "  - [%d, %d]\n", pair[0], pair[1])
		}
	}
	return sb.String()
}

// allTracesEmpty checks if every trace segment has zero events.
func allTracesEmpty(traces []TraceSegment) bool {
	for _, t := range traces {
		if len(t.Events) > 0 {
			return false
		}
	}
	return true
}

// deduplicateByCombinedEvents removes traces with identical combined event sequences,
// matching rigsc's behavior where each unique coordinate pair produces exactly one trace.
func deduplicateByCombinedEvents(traces []TraceSegment) []TraceSegment {
	if len(traces) == 0 {
		return nil
	}

	seen := make(map[string]int, len(traces)) // combinedEventSeq -> index in result
	result := make([]TraceSegment, 0, len(traces))

	for _, t := range traces {
		seq := combinedEventSequence(t.Events)
		if idx, ok := seen[seq]; ok {
			// Keep the trace with higher probability (first occurrence wins for ties).
			if t.Probability > result[idx].Probability {
				result[idx] = t
			}
			continue
		}
		seen[seq] = len(result)
		result = append(result, t)
	}

	return result
}

// combinedEventSequence builds a canonical string from event names and positions.
func combinedEventSequence(events []EventTuple) string {
	if len(events) == 0 {
		return "__empty__"
	}
	var b strings.Builder
	for _, e := range events {
		b.WriteString(e.Name)
		b.WriteByte(':')
		b.WriteString(fmt.Sprintf("%d", e.Position))
		b.WriteByte('|')
	}
	return b.String()
}
