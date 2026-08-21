// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package gpu provides utilities for querying NVIDIA GPUs via nvidia-smi and managing device selection.
package gpu

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

// GPUInfo represents a single NVIDIA GPU device with its properties.
type GPUInfo struct {
	Index           int
	Name            string
	MemoryTotalMB   int
	ComputeCapability string
}

// QueryNvidiaSmi executes nvidia-smi and returns a list of available GPUs.
func QueryNvidiaSmi() ([]GPUInfo, error) {
	cmd := exec.Command("nvidia-smi", "--query-gpu=index,name,memory.total,compute_cap", "--format=csv,noheader,nounits")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to query nvidia-smi: %w. Is CUDA driver installed?", err)
	}

	var gpus []GPUInfo
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, line := range lines {
		parts := strings.Split(line, ", ")
		if len(parts) < 4 {
			continue
		}

		index, err := strconv.Atoi(strings.TrimSpace(parts[0]))
		if err != nil {
			continue
		}

		memoryMB, err := strconv.Atoi(strings.TrimSpace(parts[2]))
		if err != nil {
			memoryMB = 0
		}

		gpus = append(gpus, GPUInfo{
			Index:           index,
			Name:            strings.TrimSpace(parts[1]),
			MemoryTotalMB:   memoryMB,
			ComputeCapability: strings.TrimSpace(parts[3]),
		})
	}

	return gpus, nil
}

// ParseGPUIndices parses a GPU specification string (e.g., "0", "0,1", "0-3") into a list of indices.
func ParseGPUIndices(spec string) ([]int, error) {
	var indices []int
	parts := strings.Split(spec, ",")

	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}

		// Check for range notation (e.g., "0-3")
		if strings.Contains(part, "-") {
			rangeParts := strings.Split(part, "-")
			if len(rangeParts) != 2 {
				return nil, fmt.Errorf("invalid GPU range: %s", part)
			}

			start, err := strconv.Atoi(strings.TrimSpace(rangeParts[0]))
			if err != nil {
				return nil, fmt.Errorf("invalid start index in range %s: %w", part, err)
			}

			end, err := strconv.Atoi(strings.TrimSpace(rangeParts[1]))
			if err != nil {
				return nil, fmt.Errorf("invalid end index in range %s: %w", part, err)
			}

			if start > end {
				return nil, fmt.Errorf("start index (%d) must be less than or equal to end index (%d) in range %s", start, end, part)
			}

			for i := start; i <= end; i++ {
				indices = append(indices, i)
			}
		} else {
			// Single index
			index, err := strconv.Atoi(part)
			if err != nil {
				return nil, fmt.Errorf("invalid GPU index: %s", part)
			}
			indices = append(indices, index)
		}
	}

	return indices, nil
}

// ValidateGPUIndices checks if requested GPU indices exist in the available list.
func ValidateGPUIndices(requested []int, available []GPUInfo) error {
	availableSet := make(map[int]bool)
	for _, gpu := range available {
		availableSet[gpu.Index] = true
	}

	for _, idx := range requested {
		if !availableSet[idx] {
			return fmt.Errorf("GPU index %d not found. Available GPUs: %v", idx, GetAvailableIndices(available))
		}
	}
	return nil
}

// GetAvailableIndices extracts just the indices from a list of GPUInfo.
func GetAvailableIndices(gpus []GPUInfo) []int {
	var indices []int
	for _, gpu := range gpus {
		indices = append(indices, gpu.Index)
	}
	return indices
}

// FormatGPUList returns a human-readable string listing all available GPUs.
func FormatGPUList(gpus []GPUInfo) string {
	if len(gpus) == 0 {
		return "No GPUs detected"
	}

	var lines []string
	for _, gpu := range gpus {
		lines = append(lines, fmt.Sprintf("  GPU %d: %s (%d MiB, Compute Capability %s)",
			gpu.Index, gpu.Name, gpu.MemoryTotalMB, gpu.ComputeCapability))
	}
	return strings.Join(lines, "\n")
}

// HasNvidiaSmi checks if nvidia-smi is available in PATH.
func HasNvidiaSmi() bool {
	_, err := exec.LookPath("nvidia-smi")
	return err == nil
}

// HasNvcc checks if nvcc (CUDA compiler) is available in PATH.
func HasNvcc() bool {
	_, err := exec.LookPath("nvcc")
	return err == nil
}
