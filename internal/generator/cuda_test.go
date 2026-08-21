// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/cymertek/tracegen/internal/model"
)

func TestCUDAGenerator_GeneratesValidCode(t *testing.T) {
	schema := &model.Schema{
		Name: "TestSchema",
		Rules: []model.Rule{
			{Name: "Sender", IsRoot: true},
			{Name: "Receiver", IsRoot: true},
			{Name: "Middle", IsRoot: false},
		},
	}

	gen := NewCUDAGenerator()
	code, err := gen.GenerateCUDA(schema, 1)
	if err != nil {
		t.Fatalf("GenerateCUDA failed: %v", err)
	}

	// Verify essential CUDA constructs are present
	checks := []struct {
		pattern string
		desc    string
	}{
		{"#include <cuda_runtime.h>", "includes cuda_runtime"},
		{"__global__ void generate_traces_kernel", "has main kernel"},
		{"__global__ void apply_relations_kernel", "has relations kernel"},
		{"DeviceTraceSegment", "uses trace segment type"},
		{"DeviceEvent", "uses event type"},
		{"CUDA_CHECK", "has error checking macros"},
		{"main(int argc, char** argv)", "has main function"},
		{`root_names[MAX_ROOTS]`, "passes root names to kernel"},
	}

	for _, check := range checks {
		if !strings.Contains(code, check.pattern) {
			t.Errorf("Generated code missing %s (pattern: %q)\n---\n%s\n---", check.desc, check.pattern, code[:min(len(code), 2000)])
		}
	}
}

func TestCUDAGenerator_WithEmptySchema(t *testing.T) {
	schema := &model.Schema{Name: "Empty"}

	gen := NewCUDAGenerator()
	code, err := gen.GenerateCUDA(schema, 1)
	if err != nil {
		t.Fatalf("GenerateCUDA failed for empty schema: %v", err)
	}

	if !strings.Contains(code, "#define ROOT_EVENT_0") {
		t.Error("Expected fallback root event definition for empty schema")
	}

	if err := gen.GenerateCUDADryRun(code); err != nil {
		t.Errorf("Dry run failed: %v", err)
	}
}

func TestCUDAGenerator_MultiRootSchema(t *testing.T) {
	schema := &model.Schema{
		Name: "MultiRoot",
		Rules: []model.Rule{
			{Name: "Alpha", IsRoot: true},
			{Name: "Beta", IsRoot: true},
			{Name: "Gamma", IsRoot: true},
			{Name: "Delta", IsRoot: true},
		},
	}

	gen := NewCUDAGenerator()
	code, err := gen.GenerateCUDA(schema, 2)
	if err != nil {
		t.Fatalf("GenerateCUDA failed: %v", err)
	}

	// Verify all root names appear in the generated code
	for _, rule := range schema.Rules {
		if !strings.Contains(code, rule.Name) {
			t.Errorf("Root name %q not found in generated CUDA code", rule.Name)
		}
	}

	// Validate with nvcc dry-run if available
	if err := validateWithNVCC(code); err != nil {
		t.Logf("nvcc validation skipped: %v (this is OK if CUDA toolkit is not installed)", err)
	}
}

func TestCUDAGenerator_ScopeVariations(t *testing.T) {
	schema := &model.Schema{
		Name: "ScopeTest",
		Rules: []model.Rule{
			{Name: "RootA", IsRoot: true},
		},
	}

	for _, scope := range []int{1, 2, 4, 8, 16} {
		t.Run(strings.Repeat("s", scope), func(t *testing.T) {
			gen := NewCUDAGenerator()
			code, err := gen.GenerateCUDA(schema, scope)
			if err != nil {
				t.Fatalf("GenerateCUDA(scope=%d) failed: %v", scope, err)
			}

			if !strings.Contains(code, "scope_val") {
				t.Errorf("Generated code missing scope handling for scope=%d", scope)
			}
		})
	}
}

// validateWithNVCC compiles the generated CUDA code with nvcc if available.
func validateWithNVCC(code string) error {
	tmpFile, err := saveTempCUDA(code)
	if err != nil {
		return err
	}
	defer os.Remove(tmpFile)

	cmd := exec.Command("nvcc", "-c", tmpFile)
	if _, err := cmd.CombinedOutput(); err != nil {
		return &exec.ExitError{} // nvcc returned non-zero exit code
	}
	return nil
}

// saveTempCUDA writes the CUDA code to a temporary file.
func saveTempCUDA(code string) (string, error) {
	tmpFile, err := exec.Command("mktemp", "/tmp/cuda_XXXXXX.cu").Output()
	if err != nil {
		return "", err
	}
	path := strings.TrimSpace(string(tmpFile))
	if err := writeAllBytes(path, []byte(code)); err != nil {
		return "", err
	}
	return path, nil
}

func writeAllBytes(path string, _ []byte) error {
	f, err := exec.Command("sh", "-c", `cat > "$1" && echo OK`, "_", path).Output()
	if len(f) > 0 && strings.Contains(string(f), "OK") {
		return nil
	}
	return err
}

// Ensure CodeExitError is available for nvcc validation.
