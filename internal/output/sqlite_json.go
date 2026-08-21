// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package output

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/cymertek/tracegen/internal/store"
)

// SQLiteToPrettyJSON reads all traces from a store and writes pretty-printed JSON to the specified path.
func SQLiteToPrettyJSON(dbStore *store.SQLiteStore, outputPath string, baseName string) error {
	traces, err := dbStore.GetAllTraces()
	if err != nil {
		return fmt.Errorf("reading traces from store: %w", err)
	}

	totalInstances, _ := dbStore.TotalInstances()

	// Build output structure matching C++ trace-generator format exactly.
	type JSONTraceOutput struct {
		Traces []store.TraceRecord `json:"traces"`
	}

	output := JSONTraceOutput{
		Traces: traces,
	}

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling to pretty JSON: %w", err)
	}

	// Write to output file.
	dir := filepath.Dir(outputPath)
	if dir != "." && dir != "" {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("creating output directory: %w", err)
		}
	}

	if err := os.WriteFile(outputPath, jsonData, 0644); err != nil {
		return fmt.Errorf("writing JSON file: %w", err)
	}

	fmt.Printf("[INFO] Generated %d unique traces (%d total instances) -> %s\n", len(traces), totalInstances, outputPath)

	return nil
}

// SQLiteToPrettyJSONStdout reads all traces from a store and writes pretty-printed JSON to stdout.
func SQLiteToPrettyJSONStdout(dbStore *store.SQLiteStore) error {
	traces, err := dbStore.GetAllTraces()
	if err != nil {
		return fmt.Errorf("reading traces from store: %w", err)
	}

	type JSONTraceOutput struct {
		Traces []store.TraceRecord `json:"traces"`
	}

	output := JSONTraceOutput{
		Traces: traces,
	}

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling to pretty JSON: %w", err)
	}

	fmt.Println(string(jsonData))
	return nil
}
