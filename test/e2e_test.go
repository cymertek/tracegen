// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Evaluation-Only License. See LICENSE file.

// Package test provides end-to-end integration tests for the tgrun toolchain.
package test

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// buildBinaries builds all three binaries and returns their paths.
func buildBinaries(t *testing.T) (tgrun, tgfmt, tglint string) {
	t.Helper()

	tmpDir := t.TempDir()
	tgrunPath := filepath.Join(tmpDir, "tgrun")
	tgfmtPath := filepath.Join(tmpDir, "tgfmt")
	tglintPath := filepath.Join(tmpDir, "tglint")

	// Build tgrun
	cmd := exec.Command("go", "build", "-o", tgrunPath, "./cmd/tgrun")
	cmd.Dir = findProjectRoot(t)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("failed to build tgrun: %v\n%s", err, out)
	}

	// Build tgfmt
	cmd = exec.Command("go", "build", "-o", tgfmtPath, "./cmd/tgfmt")
	cmd.Dir = findProjectRoot(t)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("failed to build tgfmt: %v\n%s", err, out)
	}

	// Build tglint
	cmd = exec.Command("go", "build", "-o", tglintPath, "./cmd/tglint")
	cmd.Dir = findProjectRoot(t)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("failed to build tglint: %v\n%s", err, out)
	}

	return tgrunPath, tgfmtPath, tglintPath
}

// findProjectRoot returns the absolute path to the project root.
func findProjectRoot(t *testing.T) string {
	t.Helper()

	// Walk up directories looking for go.mod
	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("failed to get working directory: %v", err)
	}

	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("could not find project root (no go.mod found)")
		}
		dir = parent
	}
}

// TestTracegenVersion verifies tgrun --version works.
func TestTracegenVersion(t *testing.T) {
	tgrun, _, _ := buildBinaries(t)

	cmd := exec.Command(tgrun, "version")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		t.Fatalf("tgrun version failed: %v\n%s", err, stderr.String())
	}

	output := strings.TrimSpace(stdout.String())
	if !strings.Contains(output, "tgrun v") && !strings.Contains(output, "version") {
		t.Errorf("unexpected version output: %s", output)
	}
}

// TestTracegenParse verifies tgrun parse command works on a real .mp file.
func TestTracegenParse(t *testing.T) {
	tgrun, _, _ := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	cmd := exec.Command(tgrun, "parse", mpFile)
	var stdout bytes.Buffer
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		t.Fatalf("tgrun parse failed: %v\n%s", err, cmd.Stderr)
	}

	output := stdout.String()
	if !strings.Contains(output, "SimpleTest") {
		t.Errorf("expected output to contain 'SimpleTest', got: %s", output)
	}
	if !strings.Contains(output, "Sender") {
		t.Errorf("expected output to contain 'Sender', got: %s", output)
	}
	if !strings.Contains(output, "Receiver") {
		t.Errorf("expected output to contain 'Receiver', got: %s", output)
	}
}

// TestTracegenRun verifies tgrun run command generates JSON traces.
func TestTracegenRun(t *testing.T) {
	tgrun, _, _ := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	tmpDir := t.TempDir()

	cmd := exec.Command(tgrun, "run", mpFile, "--scope=1", "-o", tmpDir)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		t.Fatalf("tgrun run failed: %v\n%s", err, stderr.String())
	}

	// Verify output was generated in the directory
	files, err := os.ReadDir(tmpDir)
	if err != nil {
		t.Fatalf("failed to read temp dir: %v", err)
	}

	var jsonFile string
	for _, f := range files {
		if strings.HasSuffix(f.Name(), ".json") {
			jsonFile = filepath.Join(tmpDir, f.Name())
			break
		}
	}

	if jsonFile == "" {
		t.Fatal("no JSON output file found in temp directory")
	}

	data, err := os.ReadFile(jsonFile)
	if err != nil {
		t.Fatalf("failed to read output file: %v", err)
	}

	var result struct {
		Traces []json.RawMessage `json:"traces"`
	}
	if err := json.Unmarshal(data, &result); err != nil {
		t.Fatalf("output is not valid JSON: %v\n%s", err, data)
	}

	if len(result.Traces) == 0 {
		t.Error("expected at least one trace segment")
	}
}

// TestTgfmtFormat verifies tgfmt format command works.
func TestTgfmtFormat(t *testing.T) {
	_, tgfmt, _ := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	cmd := exec.Command(tgfmt, "format", mpFile)
	var stdout bytes.Buffer
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		t.Fatalf("tgfmt format failed: %v\n%s", err, cmd.Stderr)
	}

	output := stdout.String()
	if !strings.Contains(output, "SCHEMA SimpleTest") {
		t.Errorf("expected formatted output to contain 'SCHEMA SimpleTest', got:\n%s", output)
	}
}

// TestTgfmtCheck verifies tgfmt check command works.
func TestTgfmtCheck(t *testing.T) {
	_, tgfmt, _ := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	cmd := exec.Command(tgfmt, "check", mpFile)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		t.Fatalf("tgfmt check failed: %v\n%s", err, stderr.String())
	}
}

// TestTglintLint verifies tglint lint command works.
func TestTglintLint(t *testing.T) {
	_, _, tglint := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	cmd := exec.Command(tglint, "lint", mpFile)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		// Exit code 1 means violations were found (expected for test file)
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
			t.Log("Linter found violations (expected):", stdout.String())
		} else {
			t.Fatalf("tglint lint failed unexpectedly: %v\n%s\nstdout: %s", err, stderr.String(), stdout.String())
		}
	}

	output := stdout.String()
	if output == "" {
		output = "no violations found"
	}
	t.Logf("Linter output: %s", output)
}

// TestTglintListRules verifies tglint list-rules command works.
func TestTglintListRules(t *testing.T) {
	_, _, tglint := buildBinaries(t)

	cmd := exec.Command(tglint, "list-rules")
	var stdout bytes.Buffer
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		t.Fatalf("tglint list-rules failed: %v\n%s", err, cmd.Stderr)
	}

	output := stdout.String()
	expectedRules := []string{"no-magic-numbers", "max-function-length", "no-dead-code", "naming-conventions", "missing-docs"}

	for _, rule := range expectedRules {
		if !strings.Contains(output, rule) {
			t.Errorf("expected output to contain rule '%s', got:\n%s", rule, output)
		}
	}
}

// TestEndToEndWorkflow verifies the complete workflow: format -> lint -> tgrun.
func TestEndToEndWorkflow(t *testing.T) {
	tgrun, tgfmt, tglint := buildBinaries(t)
	mpFile := filepath.Join(findProjectRoot(t), "examples", "simple_test.mp")

	if _, err := os.Stat(mpFile); err != nil {
		t.Skipf("skipping test: %s not found: %v", mpFile, err)
	}

	tmpDir := t.TempDir()
	copiedFile := filepath.Join(tmpDir, "simple_test.mp")

	// Copy MP file to temp dir for formatting
	data, err := os.ReadFile(mpFile)
	if err != nil {
		t.Fatalf("failed to read MP file: %v", err)
	}
	if err := os.WriteFile(copiedFile, data, 0644); err != nil {
		t.Fatalf("failed to write copied file: %v", err)
	}

	// Step 1: Format the file
	cmd := exec.Command(tgfmt, "format", "-w", copiedFile)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("tgfmt format failed: %v\n%s", err, out)
	}

	// Step 2: Lint the file
	cmd = exec.Command(tglint, "lint", "--severity=warning", copiedFile)
	var lintStdout bytes.Buffer
	cmd.Stdout = &lintStdout
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Logf("Linter output (expected for test file): %s\n%s", string(out), lintStdout.String())
	}

	// Step 3: Generate traces
	outputDir := filepath.Join(tmpDir, "output")
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		t.Fatalf("failed to create output dir: %v", err)
	}

	cmd = exec.Command(tgrun, "run", copiedFile, "--scope=1", "-o", outputDir)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("tgrun run failed:\n%s\nerr: %v", string(out), err)
	}

	// Verify output was generated
	files, err := os.ReadDir(outputDir)
	if err != nil {
		t.Fatalf("failed to read output directory: %v", err)
	}

	if len(files) == 0 {
		t.Error("expected trace output files in output directory")
	}

	// Verify JSON is valid
	for _, file := range files {
		if strings.HasSuffix(file.Name(), ".json") {
			data, err := os.ReadFile(filepath.Join(outputDir, file.Name()))
			if err != nil {
				t.Errorf("failed to read output file %s: %v", file.Name(), err)
				continue
			}

			var result struct {
				Traces []json.RawMessage `json:"traces"`
			}
			if err := json.Unmarshal(data, &result); err != nil {
				t.Errorf("output file %s is not valid JSON: %v\n%s", file.Name(), err, data)
			}
		}
	}
}
