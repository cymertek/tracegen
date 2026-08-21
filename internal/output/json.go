// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.
package output

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/cymertek/tracegen/internal/model"
)

// JSONTraceOutput represents the top-level JSON output structure matching C++ trace-generator.
type JSONTraceOutput struct {
	Traces []model.TraceSegment `json:"traces"`
}

// MarshalToJSON converts a slice of trace segments to JSON format matching C++ trace-generator output.
func MarshalToJSON(segments []model.TraceSegment) (string, error) {
	output := JSONTraceOutput{
		Traces: segments,
	}

	data, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return "", fmt.Errorf("error marshaling to JSON: %w", err)
	}

	return string(data), nil
}

// UnmarshalFromJSON parses JSON trace output back into TraceSegment slice.
func UnmarshalFromJSON(jsonStr string) ([]model.TraceSegment, error) {
	var output JSONTraceOutput

	err := json.Unmarshal([]byte(jsonStr), &output)
	if err != nil {
		return nil, fmt.Errorf("error unmarshaling from JSON: %w", err)
	}

	return output.Traces, nil
}

// FormatTraceSegment formats a single trace segment for display.
func FormatTraceSegment(segment model.TraceSegment, index int) string {
	var sb strings.Builder

	fmt.Fprintf(&sb, "Trace Segment #%d:\n", index+1)
	fmt.Fprintf(&sb, "  Mark Status: %s\n", segment.MarkStatus)
	fmt.Fprintf(&sb, "  Probability: %.6f\n", segment.Probability)

	if len(segment.Events) > 0 {
		sb.WriteString("  Events:\n")
		for _, event := range segment.Events {
			fmt.Fprintf(&sb, "    [%d] %s (type=%s, root_index=%d)\n",
				event.Position, event.Name, event.Type, event.RootIndex)
		}
	}

	if len(segment.FollowsPairs) > 0 {
		sb.WriteString("  Follows Pairs:\n")
		for _, pair := range segment.FollowsPairs {
			fmt.Fprintf(&sb, "    [%d] PRECEDES [%d]\n", pair[1], pair[0])
		}
	}

	if len(segment.InPairs) > 0 {
		sb.WriteString("  In Pairs:\n")
		for _, inPair := range segment.InPairs {
			switch v := inPair.(type) {
			case []interface{}:
				if len(v) >= 2 {
					fmt.Fprintf(&sb, "    %v CONTAINS %v\n", v[0], v[1])
				}
			default:
				fmt.Fprintf(&sb, "    %v\n", inPair)
			}
		}
	}

	if len(segment.UDRs) > 0 {
		sb.WriteString("  User-Defined Relations:\n")
		for relName, pairs := range segment.UDRs {
			for i := 0; i < len(pairs); i += 2 {
				if i+1 < len(pairs) {
					fmt.Fprintf(&sb, "    %s: [%d] -- %s --> [%d]\n", relName, pairs[i], relName, pairs[i+1])
				}
			}
		}
	}

	if len(segment.Views) > 0 {
		sb.WriteString("  Views:\n")
		for _, view := range segment.Views {
			switch v := view.Content.(type) {
			case string:
				fmt.Fprintf(&sb, "    [%s] %s\n", view.Type, v)
			default:
				fmt.Fprintf(&sb, "    [%s] %v\n", view.Type, v)
			}
		}
	}

	return sb.String()
}

// CompareTraces compares two sets of trace segments for equality.
func CompareTraces(a, b []model.TraceSegment) (bool, string) {
	if len(a) != len(b) {
		return false, fmt.Sprintf("different number of traces: %d vs %d", len(a), len(b))
	}

	for i := range a {
		if a[i].MarkStatus != b[i].MarkStatus {
			return false, fmt.Sprintf("trace %d: mark status differs (%s vs %s)", i, a[i].MarkStatus, b[i].MarkStatus)
		}

		if !floatEqual(a[i].Probability, b[i].Probability) {
			return false, fmt.Sprintf("trace %d: probability differs (%f vs %f)", i, a[i].Probability, b[i].Probability)
		}

		if len(a[i].Events) != len(b[i].Events) {
			return false, fmt.Sprintf("trace %d: different number of events (%d vs %d)", i, len(a[i].Events), len(b[i].Events))
		}

		for j := range a[i].Events {
			if a[i].Events[j] != b[i].Events[j] {
				return false, fmt.Sprintf("trace %d event %d: events differ (%v vs %v)", i, j, a[i].Events[j], b[i].Events[j])
			}
		}

		if len(a[i].FollowsPairs) != len(b[i].FollowsPairs) {
			return false, fmt.Sprintf("trace %d: different number of follows pairs", i)
		}

		for j := range a[i].FollowsPairs {
			if a[i].FollowsPairs[j] != b[i].FollowsPairs[j] {
				return false, fmt.Sprintf("trace %d follows pair %d differs", i, j)
			}
		}
	}

	return true, "traces match"
}

func floatEqual(a, b float64) bool {
	const epsilon = 1e-9
	return abs(a-b) < epsilon
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}
