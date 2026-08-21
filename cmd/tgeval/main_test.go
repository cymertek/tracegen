// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package main

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

// projectRoot is cached across tests to avoid repeated lookups.
var projectRoot string

func findProjectRoot(t *testing.T) string {
	if projectRoot != "" {
		return projectRoot
	}
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			projectRoot = dir
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("could not find project root (no go.mod)")
		}
		dir = parent
	}
}

func TestTgevalVersion(t *testing.T) {
	cmd := exec.Command("go", "run", ".", "version")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("tgeval version failed: %v\n%s", err, output)
	}

	outStr := string(output)
	if !strings.Contains(outStr, "tgeval v1.0.0") && !strings.Contains(outStr, "version") {
		t.Errorf("unexpected version output: %s", outStr)
	}
}

func TestTgevalCount(t *testing.T) {
	root := findProjectRoot(t)
	for _, mpFile := range []string{
		filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp"),
		filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example02_Data_flow.mp"),
	} {
		t.Run(filepath.Base(mpFile), func(t *testing.T) {
			cmd := exec.Command("go", "run", ".", "count", "--scope=1", mpFile)
			output, err := cmd.CombinedOutput()
			if err != nil {
				t.Fatalf("tgeval count failed: %v\n%s", err, output)
			}

			outStr := strings.TrimSpace(string(output))
			count, err := strconv.Atoi(outStr)
			if err != nil {
				t.Errorf("count output is not a valid integer: %q", outStr)
				return
			}

			if count <= 0 {
				t.Errorf("expected positive trace count for %s, got %d", mpFile, count)
			}
		})
	}
}

func TestTgevalEvalOutputsValidJSON(t *testing.T) {
	root := findProjectRoot(t)
	tmpDir := t.TempDir()
	outputPath := filepath.Join(tmpDir, "traces.json")

	mpFile := filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp")
	cmd := exec.Command("go", "run", ".", "eval", "-o", outputPath, mpFile)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("tgeval eval failed: %v\n%s", err, output)
	}

	jsonData, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatal(err)
	}

	var result struct {
		Traces []json.RawMessage `json:"traces"`
	}
	if err := json.Unmarshal(jsonData, &result); err != nil {
		t.Fatalf("output is not valid JSON: %v\n%s", err, jsonData)
	}

	if len(result.Traces) == 0 {
		t.Error("expected at least one trace segment")
	}
}

func TestTgevalSummary(t *testing.T) {
	root := findProjectRoot(t)
	cmd := exec.Command("go", "run", ".", "summary", "--quiet",
		filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp"))
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("tgeval summary failed: %v\n%s", err, output)
	}

	var result traceSummaryResult
	if err := json.Unmarshal(output, &result); err != nil {
		t.Fatalf("summary output is not valid JSON: %v\n%s", err, output)
	}

	if result.TotalTraces <= 0 {
		t.Error("expected positive total_traces in summary")
	}
	if result.Scope != 1 {
		t.Errorf("expected scope=1, got %d", result.Scope)
	}
}

func TestTgevalInvalidFile(t *testing.T) {
	cmd := exec.Command("go", "run", ".", "eval", "--scope=1", "/nonexistent/file.mp")
	output, err := cmd.CombinedOutput()
	if err == nil {
		t.Error("expected error for nonexistent file")
	}

	if !strings.Contains(strings.ToLower(string(output)), "error") &&
	   !strings.Contains(strings.ToLower(string(output)), "no such file") {
		t.Logf("Error output: %s", string(output))
	}
}

func TestTgevalMultipleFiles(t *testing.T) {
	root := findProjectRoot(t)
	tmpDir := t.TempDir()
	outputPath := filepath.Join(tmpDir, "output.json")

	files := []string{
		filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp"),
		filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example02_Data_flow.mp"),
	}

	cmd := exec.Command("go", "run", ".", "eval", "-o", outputPath)
	for _, f := range files {
		cmd.Args = append(cmd.Args, f)
	}

	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("tgeval eval multiple failed: %v\n%s", err, output)
	}

	jsonData, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatal(err)
	}

	var result struct {
		Traces []json.RawMessage `json:"traces"`
	}
	if err := json.Unmarshal(jsonData, &result); err != nil {
		t.Fatalf("output is not valid JSON: %v\n%s", err, jsonData)
	}

	// Both files processed — should have traces from first file only (last write wins for single output path)
	if len(result.Traces) == 0 {
		t.Error("expected trace segments in output")
	}
}

func TestTgevalScopeVariation(t *testing.T) {
	root := findProjectRoot(t)
	mpFile := filepath.Join(root, "trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp")
	for _, scope := range []int{1, 2, 3} {
		t.Run(strconv.Itoa(scope), func(t *testing.T) {
			cmd := exec.Command("go", "run", ".", "count", "--scope="+strconv.Itoa(scope), mpFile)
			output, err := cmd.CombinedOutput()
			if err != nil {
				t.Fatalf("tgeval count scope=%d failed: %v\n%s", scope, err, output)
			}

			count, err := strconv.Atoi(strings.TrimSpace(string(output)))
			if err != nil {
				t.Errorf("count output is not a valid integer at scope %d: %q", scope, string(output))
				return
			}

			if count <= 0 {
				t.Errorf("expected positive trace count at scope=%d, got %d", scope, count)
			}
		})
	}
}

// traceSummaryResult matches the JSON structure produced by tgeval summary.
type traceSummaryResult struct {
	SchemaName  string `json:"schema_name"`
	Scope       int    `json:"scope"`
	TotalTraces int    `json:"total_traces"`
	Marked      int    `json:"marked"`
	Unmarked    int    `json:"unmarked"`
}
