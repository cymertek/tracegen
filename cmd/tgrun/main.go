// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements the CYMERTEK CUDA Trace Generator CLI.
package main

import (
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/cymertek/tracegen/internal/generator"
	"github.com/cymertek/tracegen/internal/gpu"
	"github.com/cymertek/tracegen/internal/help"
	"github.com/cymertek/tracegen/internal/model"
	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

// uid returns the current user's UID for cache isolation.
func uid() string {
	u := os.Getenv("USER")
	if u != "" {
		return u
	}
	uid := os.Geteuid()
	return fmt.Sprintf("%d", uid)
}

const version = "1.0.0"

// Global flag to control cache cleanup after runs
var cleanCache bool

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "run", "":
		runCommand(args)
	case "parse":
		parseCommand(args)
	case "version", "--version", "-V":
		fmt.Printf("tgrun v%s\n", version)
	case "help", "--help", "-h":
		if len(args) > 0 {
			helpCommand(args[0])
		} else {
			printUsage()
		}
	default:
		// If the first argument looks like an .mp file, treat it as run <file> with flags
		if strings.HasSuffix(command, ".mp") {
			runCommand(append([]string{command}, args...))
			return
		}
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

// helpCommand displays embedded documentation for the given topic.
func helpCommand(topic string) {
	switch strings.ToLower(topic) {
	case "setup-gpu":
		fmt.Println(help.SetupGPU)
	case "troubleshooting":
		fmt.Println(help.Troubleshooting)
	case "architecture":
		fmt.Println(help.Architecture)
	case "quick-reference", "qr":
		fmt.Println(help.QuickReference)
	default:
		fmt.Fprintf(os.Stderr, "Unknown help topic: %s\n", topic)
		fmt.Fprintln(os.Stderr, "\nAvailable topics:")
		fmt.Fprintln(os.Stderr, "  setup-gpu          GPU installation and configuration guide")
		fmt.Fprintln(os.Stderr, "  troubleshooting     Common issues and solutions")
		fmt.Fprintln(os.Stderr, "  architecture        How tgrun works with GPUs")
		fmt.Fprintln(os.Stderr, "  quick-reference     Quick command reference")
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`tgrun - CYMERTEK CUDA Trace Generator for Monterey Phoenix

A high-performance trace generator for Monterey Phoenix behavioral models.
Compiles to CPU by default; use --gpus=N or --backend=cuda for CUDA code generation.

Usage:
  tgrun <file.mp> [flags]              Run traces (default — no subcommand needed)
      --scope=N            Iteration scope (default: 1)
      -s N                 Short form of --scope
      --gpus=N             Compile and run on GPU devices (e.g., --gpus 0)
                           Adds CUDA code generation + runtime execution. Default: CPU-only compilation.
      --checkpoint=FILE    Write completed segments to JSON Lines file for resume support
      --backend=cpu|cuda   Code generation backend (default: cpu)
      -o FILE              Output file (.cu for CUDA code, .json/.mp for traces)
      --build-only         Generate CUDA files without running traces (-b)
      -k, --clean          Delete cache directory after run
      -v, --verbose        Show detailed progress information
      -q, --quiet          Suppress non-error output

  tgrun parse <file.mp> [flags]   Validate MP file syntax and print AST summary
      --ast                Print parsed AST in JSON format
      -v, --verbose        Show detailed parsing information

  tgrun help TOPIC           Show help topic (offline)
                           Available topics: setup-gpu, troubleshooting, architecture, quick-reference

  version          Display version information

Flags:
  -h, --help         Show this help message or help for a specific topic
  -V, --version      Print version information

Examples:
  tgrun Example01_simple_message_flow.mp --scope=2
  tgrun complex_model.mp --gpus 0,1 --scope=3    # Use GPUs 0 and 1
  tgrun buggy_model.mp parse --ast                  # Parse and show AST
  tgrun --help setup-gpu                            # Show GPU setup instructions`)
}

// runCommand handles the default behavior: tgrun <file.mp> [flags].
func runCommand(args []string) {
	scope := 1
	numSegments := 1
	backend := "cpu" // Default to CPU-only; use --gpus=N or --backend=cuda for GPU compilation
	outputDir := "./output"
	buildOnly := false
	gpuSpec := "" // Empty means use all available GPUs or CPU fallback
	checkpointFile := ""
	verbose := false
	quiet := false
	cleanCache = false // Reset flag for this command
	var mpFile string

	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "-k" || arg == "--clean":
			cleanCache = true
		case arg == "--gpus" && i+1 < len(args):
			i++
			gpuSpec = args[i]
		case strings.HasPrefix(arg, "--gpus="):
			gpuSpec = strings.TrimPrefix(arg, "--gpus=")
		case arg == "--scope" && i+1 < len(args):
			i++
			if _, err := fmt.Sscanf(args[i], "%d", &scope); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid scope value: %v\n", err)
			}
		case arg == "--scope=" || strings.HasPrefix(arg, "--scope="):
			if strings.HasPrefix(arg, "--scope=") {
				if _, err := fmt.Sscanf(arg, "--scope=%d", &scope); err != nil {
					fmt.Fprintf(os.Stderr, "Warning: invalid scope value: %v\n", err)
				}
			} else if i+1 < len(args) {
				i++
				if _, err := fmt.Sscanf(args[i], "%d", &scope); err != nil {
					fmt.Fprintf(os.Stderr, "Warning: invalid scope value: %v\n", err)
				}
			}
		case arg == "-s" && i+1 < len(args):
			i++
			if _, err := fmt.Sscanf(args[i], "%d", &scope); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid scope value: %v\n", err)
			}
		case arg == "--backend" && i+1 < len(args):
			i++
			backend = args[i]
		case arg == "--backend=" || strings.HasPrefix(arg, "--backend="):
			if strings.HasPrefix(arg, "--backend=") {
				backend = strings.TrimPrefix(arg, "--backend=")
			} else if i+1 < len(args) {
				i++
				backend = args[i]
			}
		case arg == "--build-only":
			buildOnly = true
		case arg == "-b" && !strings.HasPrefix(arg, "--backend"):
			if i+1 >= len(args) || strings.HasPrefix(args[i+1], "-") {
				buildOnly = true
			} else if i+1 < len(args) {
				i++
				backend = args[i]
			}
		case arg == "--output-dir=" || strings.HasPrefix(arg, "--output-dir="):
			if strings.HasPrefix(arg, "--output-dir=") {
				outputDir = strings.TrimPrefix(arg, "--output-dir=")
			} else if i+1 < len(args) {
				i++
				outputDir = args[i]
			}
		case arg == "-o" && i+1 < len(args):
			i++
			outputDir = args[i]
		case arg == "--verbose" || arg == "-v":
			verbose = true
		case arg == "--checkpoint" && i+1 < len(args):
			i++
			checkpointFile = args[i]
		case strings.HasPrefix(arg, "--checkpoint="):
			checkpointFile = strings.TrimPrefix(arg, "--checkpoint=")
		case arg == "--num-segments" && i+1 < len(args):
			i++
			if _, err := fmt.Sscanf(args[i], "%d", &numSegments); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid num-segments value: %v\n", err)
			}
		case strings.HasPrefix(arg, "--num-segments="):
			if _, err := fmt.Sscanf(strings.TrimPrefix(arg, "--num-segments="), "%d", &numSegments); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid num-segments value: %v\n", err)
			}
		case arg == "--quiet" || arg == "-q":
			quiet = true
		case !strings.HasPrefix(arg, "-"):
			mpFile = arg
		}
	}

	if mpFile == "" {
		fmt.Fprintln(os.Stderr, "Error: tgrun requires an MP file argument")
		os.Exit(1)
	}

	input, err := os.ReadFile(mpFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error tokenizing %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	p := parser.NewParser(tokens)
	schemaNode, err := p.Parse()
	if err != nil {
		errMsg := formatErrorWithContext(string(input), err)
		fmt.Fprintln(os.Stderr, errMsg)
		os.Exit(2)
	}

	if verbose && !quiet {
		fmt.Printf("[INFO] Parsed MP file: %s (%d tokens)\n", mpFile, len(tokens))
	}

	selectedBackend, gpuIndices, warnings := selectBackendAndGPUs(backend, gpuSpec)
	for _, w := range warnings {
		fmt.Fprintln(os.Stderr, w)
	}
	if verbose && !quiet {
		fmt.Printf("[INFO] Selected backend: %s\n", selectedBackend)
		if len(gpuIndices) > 0 {
			fmt.Printf("[GPU] Using devices: %v\n", gpuIndices)
		}
	}

	baseName := strings.TrimSuffix(filepath.Base(mpFile), ".mp")

	cacheDir := buildCacheDir(schemaNode, scope)

	// Generate CUDA code if backend is cuda or user wants .cu output
	if selectedBackend == "cuda" || buildOnly || strings.HasSuffix(outputDir, ".cu") {
		var cuOutputFile string
		if filepath.Ext(outputDir) == ".cu" {
			cuOutputFile = outputDir
		} else {
			cuOutputFile = filepath.Join(outputDir, baseName+".cu")
		}
		modelSchema := convertToModelSchema(schemaNode)

		// Use SQLite-backed CUDA generator for unlimited traces with deduplication (matches tgeval approach)
		var cuCode string
		if selectedBackend == "cuda" {
			cuCode, err = generator.NewCUDASQLiteGenerator().GenerateCUDAWithSQLite(modelSchema, scope)
		} else {
			cuCode, err = generator.NewCUDAGenerator().GenerateCUDA(modelSchema, scope)
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error generating CUDA code: %v\n", err)
			os.Exit(3)
		}

		outputDirParent := filepath.Dir(cuOutputFile)
		if err := os.MkdirAll(outputDirParent, 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Error creating output directory: %v\n", err)
			os.Exit(1)
		}

		if err := os.WriteFile(cuOutputFile, []byte(cuCode), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "Error writing CUDA code to %s: %v\n", cuOutputFile, err)
			os.Exit(1)
		}

		if !quiet {
			fmt.Printf("[INFO] Generated CUDA file -> %s (scope=%d)\n", cuOutputFile, scope)
		}

		// If build-only or output is .cu, just return without executing
		if buildOnly || strings.HasSuffix(outputDir, ".cu") {
			return
		}

		// Compile and execute the CUDA code on specified GPUs
		exePath := filepath.Join(outputDirParent, baseName+"_gpu")
		if err := compileAndExecuteCUDA(cuOutputFile, exePath, gpuIndices, scope, numSegments, checkpointFile); err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] Failed to compile or execute CUDA code: %v\n", err)
			fmt.Fprintln(os.Stderr, "[HINT] Run 'tgrun --help setup-gpu' for installation instructions")
			os.Exit(3)
		}

		// Read output from the executed binary if it produced JSON
		outputJSONPath := filepath.Join(outputDirParent, baseName+".json")
		if data, err := os.ReadFile(outputJSONPath); err == nil {
			jsonStr := string(data)
			if !quiet {
				fmt.Printf("[INFO] Generated %d traces -> %s (cache: %s)\n", scope, outputJSONPath, cacheDir)
			}

			// Cache the result
			if err := os.MkdirAll(cacheDir, 0755); err != nil {
				fmt.Fprintf(os.Stderr, "[WARN] Failed to create cache dir %s: %v\n", cacheDir, err)
			} else {
				cacheJSON := filepath.Join(cacheDir, baseName+".json")
				if err := os.WriteFile(cacheJSON, []byte(jsonStr), 0644); err != nil {
					fmt.Fprintf(os.Stderr, "[WARN] Failed to cache trace output: %v\n", err)
				}
			}

			// Clean up if requested
			if cleanCache {
				if err := os.RemoveAll(cacheDir); err != nil {
					fmt.Fprintf(os.Stderr, "[WARN] Failed to clean cache %s: %v\n", cacheDir, err)
				} else {
					fmt.Printf("[INFO] Cleaned cache directory: %s\n", cacheDir)
				}
			}
		}
		return
	}

	gen := generator.NewCPUGenerator(0)

	// Use SQLite-backed streaming for all scopes — no memory accumulation, unlimited traces.
	dbStore, err := store.NewSQLiteStore(outputDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] Failed to create SQLite store: %v\n", err)
		os.Exit(1)
	}
	defer dbStore.Close()

	// Clear any previous traces from this store.
	if err := dbStore.ClearAll(); err != nil {
		fmt.Fprintf(os.Stderr, "[WARN] Failed to clear trace store: %v\n", err)
	}

	if err := gen.GenerateTracesToSQLite(schemaNode, scope, dbStore); err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] Streaming generation failed: %v\n", err)
		os.Exit(3)
	}

	uniqueCount, _ := dbStore.TotalTraces()
	totalInstances, _ := dbStore.TotalInstances()

	if !quiet {
		fmt.Printf("[INFO] Generated %d unique traces (%d total instances)\n", uniqueCount, totalInstances)
	}

	// Produce pretty-printed JSON output from SQLite.
	jsonStr, err := generator.MarshalToJSONFromStore(dbStore)
	if err != nil {
		fmt.Fprintf(os.Stderr, "[ERROR] Error marshaling traces to JSON: %v\n", err)
		os.Exit(3)
	}

	outputPath := filepath.Join(outputDir, baseName+".json")

	if err := os.MkdirAll(outputDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Error creating output directory: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile(outputPath, []byte(jsonStr), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing JSON output: %v\n", err)
		os.Exit(1)
	}

	// Cache the result in /tmp/tgrun-<hash>/ so repeated runs skip regeneration.
	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "[WARN] Failed to create cache dir %s: %v\n", cacheDir, err)
	} else {
		cacheJSON := filepath.Join(cacheDir, baseName+".json")
		if err := os.WriteFile(cacheJSON, []byte(jsonStr), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "[WARN] Failed to cache trace output: %v\n", err)
		}
	}

	if !quiet {
		fmt.Printf("[INFO] Generated %d unique traces -> %s (cache: %s)\n", uniqueCount, outputPath, cacheDir)
	}

	// Clean up cache directory if --clean flag was specified.
	if cleanCache {
		if err := os.RemoveAll(cacheDir); err != nil {
			fmt.Fprintf(os.Stderr, "[WARN] Failed to clean cache %s: %v\n", cacheDir, err)
		} else {
			fmt.Printf("[INFO] Cleaned cache directory: %s\n", cacheDir)
		}
	}
}

// parseCommand handles `tgrun parse <file.mp>`.
func parseCommand(args []string) {
	var mpFile string
	printAST := false
	verbose := false
	cleanCache = false // Reset flag for this command

	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch {
		case arg == "-k" || arg == "--clean":
			cleanCache = true
		case arg == "--ast" || arg == "-a":
			printAST = true
		case arg == "--verbose" || arg == "-v":
			verbose = true
		case !strings.HasPrefix(arg, "-"):
			mpFile = arg
		}
	}

	if mpFile == "" {
		fmt.Fprintln(os.Stderr, "Error: parse command requires an MP file argument")
		os.Exit(1)
	}

	input, err := os.ReadFile(mpFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error tokenizing %s: %v\n", mpFile, err)
		os.Exit(2)
	}

	p := parser.NewParser(tokens)
	schemaNode, err := p.Parse()
	if err != nil {
		errMsg := formatErrorWithContext(string(input), err)
		fmt.Fprintln(os.Stderr, errMsg)
		os.Exit(2)
	}

	if verbose {
		fmt.Printf("[INFO] Parsed %s successfully (%d tokens)\n", mpFile, len(tokens))
	}

	if printAST {
		astJSON := schemaNodeToJSON(schemaNode)
		fmt.Println(astJSON)
	} else {
		printSchemaSummary(schemaNode)
	}

	// Note: parse doesn't currently use cache, but supports --clean flag for consistency
	if cleanCache {
		fmt.Println("[INFO] Cache cleanup requested (no cache directory created)")
	}
}

// buildCacheDir computes a SHA1 hash from the parsed MP schema (not raw file bytes),
// so comments and whitespace changes don't affect cache hits. Produces /tmp/tgrun-<user>-<hex>/.
func buildCacheDir(schema *parser.SchemaNode, scope int) string {
	// Marshal schema to canonical MP text — this strips comments/whitespace variations
	canonical := schema.Marshal()
	data := fmt.Sprintf("%s:%d", canonical, scope)
	h := sha1.New()
	h.Write([]byte(data))
	hashHex := hex.EncodeToString(h.Sum(nil))[:8] // short 8-char hash for readability

	// Include user ID to prevent cross-user cache collisions
	userID := uid()
	return filepath.Join("/tmp", fmt.Sprintf("tgrun-%s-%s", userID, hashHex))
}

// selectBackendAndGPUs determines the backend and GPU indices based on user preference and availability.
func selectBackendAndGPUs(userBackend string, gpuSpec string) (string, []int, []string) {
	var warnings []string

	// If --gpus specified, CUDA is required
	if gpuSpec != "" {
		gpuIndices, err := gpu.ParseGPUIndices(gpuSpec)
		if err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] Invalid GPU specification: %v\n", err)
			os.Exit(1)
		}

		// Check if CUDA is available
		if !gpu.HasNvidiaSmi() {
			fmt.Fprintln(os.Stderr, "[ERROR] nvidia-smi not found. CUDA driver may not be installed.")
			fmt.Fprintln(os.Stderr, "[HINT] Run 'tgrun --help setup-gpu' for installation instructions")
			os.Exit(1)
		}

		if !gpu.HasNvcc() {
			fmt.Fprintln(os.Stderr, "[ERROR] nvcc (CUDA compiler) not found in PATH.")
			fmt.Fprintln(os.Stderr, "[HINT] Install CUDA toolkit and ensure /usr/local/cuda/bin is in your PATH")
			fmt.Fprintln(os.Stderr, "[HINT] Run 'tgrun --help setup-gpu' for installation instructions")
			os.Exit(1)
		}

		// Query available GPUs
		availableGPUs, err := gpu.QueryNvidiaSmi()
		if err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] Failed to query GPUs: %v\n", err)
			fmt.Fprintln(os.Stderr, "[HINT] Run 'tgrun --help troubleshooting' for common issues")
			os.Exit(1)
		}

		if len(availableGPUs) == 0 {
			fmt.Fprintln(os.Stderr, "[ERROR] No CUDA devices detected.")
			fmt.Fprintln(os.Stderr, "[HINT] Check that NVIDIA drivers are loaded: lsmod | grep nvidia")
			os.Exit(1)
		}

		// Validate requested GPUs exist
		if err := gpu.ValidateGPUIndices(gpuIndices, availableGPUs); err != nil {
			fmt.Fprintf(os.Stderr, "[ERROR] %v\n", err)
			fmt.Printf("\n[INFO] Available GPUs:\n%s\n", gpu.FormatGPUList(availableGPUs))
			os.Exit(1)
		}

		if warnings == nil {
			warnings = []string{}
		}
		for _, g := range availableGPUs {
			if containsInt(gpuIndices, g.Index) {
				warnings = append(warnings, fmt.Sprintf("[GPU] Device %d: %s (%d MiB, Compute Capability %s)",
					g.Index, g.Name, g.MemoryTotalMB, g.ComputeCapability))
			}
		}

		return "cuda", gpuIndices, warnings
	}

	// No --gpus specified, use auto-detection or user preference
	if userBackend == "cpu" {
		return "cpu", nil, nil
	}

	if userBackend == "cuda" || userBackend == "auto" {
		if !gpu.HasNvidiaSmi() {
			warnings = append(warnings, "[WARN] nvidia-smi not found, falling back to CPU backend")
			return "cpu", nil, warnings
		}

		if !gpu.HasNvcc() {
			warnings = append(warnings, "[WARN] nvcc not found, falling back to CPU backend")
			return "cpu", nil, warnings
		}

		availableGPUs, err := gpu.QueryNvidiaSmi()
		if err != nil || len(availableGPUs) == 0 {
			warnings = append(warnings, "[WARN] No CUDA devices detected, falling back to CPU backend")
			return "cpu", nil, warnings
		}

		// Use all available GPUs
		allIndices := gpu.GetAvailableIndices(availableGPUs)
		if warnings == nil {
			warnings = []string{}
		}
		for _, idx := range allIndices {
			warnings = append(warnings, fmt.Sprintf("[GPU] Device %d: %s", idx, availableGPUs[idx].Name))
		}

		return "cuda", allIndices, warnings
	}

	return "cpu", nil, warnings
}

func containsInt(slice []int, val int) bool {
	for _, item := range slice {
		if item == val {
			return true
		}
	}
	return false
}

// compileAndExecuteCUDA compiles and executes CUDA code on the specified GPU devices.
func compileAndExecuteCUDA(cuFile string, exePath string, gpuIndices []int, scope int, numSegments int, checkpointFile string) error {
	if len(gpuIndices) == 0 {
		return fmt.Errorf("no GPU indices specified")
	}

	// Set CUDA_VISIBLE_DEVICES to restrict which GPUs are visible
	var deviceStrings []string
	for _, idx := range gpuIndices {
		deviceStrings = append(deviceStrings, fmt.Sprintf("%d", idx))
	}
	deviceEnv := fmt.Sprintf("CUDA_VISIBLE_DEVICES=%s", strings.Join(deviceStrings, ","))

	// Compile with nvcc using relocatable device code for nested kernel launches
	fmt.Printf("[INFO] Compiling CUDA code with nvcc...\n")
	compileCmd := exec.Command("nvcc", "-O3", "-arch=sm_70", "-rdc=true", "-o", exePath, cuFile, "-lcudart")
	compileCmd.Env = append(os.Environ(), deviceEnv)

	if output, err := compileCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("nvcc compilation failed: %w\nOutput: %s", err, string(output))
	}

	fmt.Printf("[INFO] Compilation successful. Executing on GPU devices...\n")

	// Build execution args - add num-segments and checkpoint flags if specified
	executeArgs := []string{}
	if numSegments > 1 {
		executeArgs = append(executeArgs, "--num-segments", fmt.Sprintf("%d", numSegments))
	}
	if checkpointFile != "" {
		executeArgs = append(executeArgs, "--checkpoint", checkpointFile)

		// Check for existing checkpoint to support resume.
		// Each line in the checkpoint file is one segment JSON object.
		// The CUDA kernel treats --start-segment as an event offset (segment_index * scope_val),
		// so multiply line count by scope_val to get the correct skip offset.
		startSegment := 0
		if data, err := os.ReadFile(checkpointFile); err == nil && len(data) > 0 {
			lineCount := strings.Count(string(data), "\n")
			if lineCount > 0 {
				startSegment = lineCount * scope
				fmt.Printf("[INFO] Resuming from checkpoint: %d segments already completed (skipping events [0..%d])\n", lineCount, startSegment)
			}
		}
		executeArgs = append(executeArgs, "--start-segment", fmt.Sprintf("%d", startSegment))
	}

	// Execute the compiled binary with optional checkpoint support
	executeCmd := exec.Command(exePath, executeArgs...)
	executeCmd.Env = append(os.Environ(), deviceEnv)

	if output, err := executeCmd.CombinedOutput(); err != nil {
		return fmt.Errorf("CUDA execution failed: %w\nOutput: %s", err, string(output))
	} else if len(output) > 0 {
		fmt.Printf("[INFO] CUDA execution output:\n%s\n", string(output))
	}

	return nil
}

func printSchemaSummary(schema *parser.SchemaNode) {
	fmt.Printf("SCHEMA %s\n", schema.Name)
	for _, rule := range schema.Rules {
		if rule.IsRoot {
			fmt.Printf("  ROOT %s\n", rule.Name)
		} else {
			fmt.Printf("  RULE %s\n", rule.Name)
		}
	}
	if len(schema.Coordinates) > 0 {
		fmt.Println("  COORDINATE:")
		for range schema.Coordinates {
			// Simplified — full coord details printed with --ast
		}
	}
	for _, attr := range schema.Attributes {
		fmt.Printf("  ATTRIBUTE %s: %s\n", attr.Name, attr.Type)
	}
}

// convertToModelSchema converts a parser.SchemaNode to model.Schema.
func convertToModelSchema(schema *parser.SchemaNode) *model.Schema {
	ms := &model.Schema{
		Name: schema.Name,
	}
	for _, attr := range schema.Attributes {
		ms.Attributes = append(ms.Attributes, model.AttributeDeclaration{
			Name: attr.Name,
			Type: attr.Type,
		})
	}
	return ms
}

// schemaNodeToJSON converts a SchemaNode to a simple JSON representation.
func schemaNodeToJSON(schema *parser.SchemaNode) string {
	var sb strings.Builder
	sb.WriteString("{\n")
	fmt.Fprintf(&sb, "  \"name\": %q,\n", schema.Name)

	sb.WriteString("  \"rules\": [")
	for i, r := range schema.Rules {
		if i > 0 {
			sb.WriteString(", ")
		}
		fmt.Fprintf(&sb, "%q", r.Name)
	}
	sb.WriteString("],\n")

	sb.WriteString("  \"roots\": [")
	rootCount := 0
	for _, r := range schema.Rules {
		if r.IsRoot {
			if rootCount > 0 {
				sb.WriteString(", ")
			}
			fmt.Fprintf(&sb, "%q", r.Name)
			rootCount++
		}
	}
	sb.WriteString("],\n")

	sb.WriteString("  \"attributes\": [")
	for i, a := range schema.Attributes {
		if i > 0 {
			sb.WriteString(", ")
		}
		fmt.Fprintf(&sb, "%q", fmt.Sprintf("%s:%s", a.Name, a.Type))
	}
	sb.WriteString("],\n")

	fmt.Fprintf(&sb, "  \"coordinates\": %d\n", len(schema.Coordinates))
	sb.WriteString("}\n")
	return sb.String()
}
// formatErrorWithContext extracts surrounding lines from the original input and formats a helpful error message.
func formatErrorWithContext(input string, err error) string {
	// Try to extract line/column from ParseError if available
	var parseErr parser.ParseError
	if errors.As(err, &parseErr) {
		line := parseErr.Token.Line
		col := parseErr.Token.Column

		lines := strings.Split(input, "\n")

		// Build context: 2 lines before, offending line, 2 lines after
		start := max(0, line-3)
		end := min(len(lines), line+2)

		var buf strings.Builder
		buf.WriteString(fmt.Sprintf("\n=== Parse Error at line %d, column %d ===\n", line, col))
		buf.WriteString(err.Error())
		buf.WriteString("\n\n--- Context (showing lines ")
		buf.WriteString(fmt.Sprintf("%d-%d ---\n", start+1, end))

		for i := start; i < end; i++ {
			lineNum := i + 1
			if lineNum == line {
				buf.WriteString(fmt.Sprintf(">>> %3d | %s\n", lineNum, lines[i]))
				// Show column pointer
				padding := strings.Repeat(" ", col-1)
				buf.WriteString(fmt.Sprintf("    |     %s^\n", padding))
			} else {
				buf.WriteString(fmt.Sprintf("    %3d | %s\n", lineNum, lines[i]))
			}
		}

		// Detect bracket mismatches - scan all lines up to error line for unclosed brackets
		if hasCrossLineBracketMismatch(lines, line-1) {
			buf.WriteString("\n⚠️  Possible bracket mismatch detected!\n")
			buf.WriteString("   Check that all opening brackets have matching closing brackets.\n")

			// Try to find the matching opening bracket for common pairs
			bracketPairs := []struct{ open, close rune }{{'(', ')'}, {'{', '}'}, {'[', ']'}}
			for _, pair := range bracketPairs {
				openLine := findMatchingBracket(lines, line-1, pair.open)
				if openLine > 0 {
					if openLine == line {
						// Opening bracket is on the same line as error - show inline hint
						buf.WriteString(fmt.Sprintf("   ⚠️  Unmatched opening '%c' found on this line (%d)\n", pair.open, openLine))
						buf.WriteString(fmt.Sprintf("     The closing '%c' is missing or on a different line.\n", pair.close))
					} else {
						buf.WriteString(fmt.Sprintf("   Opening '%c' found on line %d:\n", pair.open, openLine))

						// Show context around the opening bracket
						startShow := max(0, openLine-2)
						endShow := min(len(lines), openLine+3)

						if endShow-startShow > 5 { // If too far apart from error line, show ...
							buf.WriteString(fmt.Sprintf("     %3d | %s\n", startShow+1, lines[startShow]))
							buf.WriteString("       |     ...\n")
							buf.WriteString(fmt.Sprintf("     >>>%3d | %s\n", openLine, lines[openLine-1]))
						} else { // If close together, show full context without ...
							for j := startShow; j < endShow; j++ {
								lNum := j + 1
								marker := ""
								if lNum == openLine {
									marker = ">>>"
								}
								buf.WriteString(fmt.Sprintf("     %s%3d | %s\n", marker, lNum, lines[j]))
							}
						}

						buf.WriteString(fmt.Sprintf("   Closing '%c' on line %d:\n", pair.close, line))
						buf.WriteString(fmt.Sprintf("     >>>%3d | %s\n", line, lines[line-1]))
					}
					break // Show only the first mismatch found
				}
			}
		}

		return buf.String()
	}

	// Fallback: just return the error as-is
	return err.Error()
}

// hasCrossLineBracketMismatch checks if there are unclosed brackets across multiple lines up to the error line.
func hasCrossLineBracketMismatch(lines []string, errorLineIdx int) bool {
	stack := []rune{}
	for i := 0; i <= errorLineIdx && i < len(lines); i++ {
		line := lines[i]
		for _, ch := range line {
			switch ch {
			case '(', '{', '[':
				stack = append(stack, ch)
			case ')':
				if len(stack) == 0 || stack[len(stack)-1] != '(' {
					return true // Unmatched closing bracket
				}
				stack = stack[:len(stack)-1]
			case '}':
				if len(stack) == 0 || stack[len(stack)-1] != '{' {
					return true // Unmatched closing bracket
				}
				stack = stack[:len(stack)-1]
			case ']':
				if len(stack) == 0 || stack[len(stack)-1] != '[' {
					return true // Unmatched closing bracket
				}
				stack = stack[:len(stack)-1]
			}
		}
	}
	return len(stack) > 0 // Unclosed opening brackets remain
}


// findMatchingBracket finds the line number of a matching opening bracket.
func findMatchingBracket(lines []string, closeLine int, _ rune) int {
	stack := []struct{ char rune; line int }{}

	for i := 0; i < len(lines); i++ {
		line := lines[i]
		for _, ch := range line {
			switch ch {
			case '(', '{', '[':
				stack = append(stack, struct{ char rune; line int }{ch, i + 1})
			case ')':
				if len(stack) > 0 && stack[len(stack)-1].char == '(' {
					stack = stack[:len(stack)-1]
				}
			case '}':
				if len(stack) > 0 && stack[len(stack)-1].char == '{' {
					stack = stack[:len(stack)-1]
				}
			case ']':
				if len(stack) > 0 && stack[len(stack)-1].char == '[' {
					stack = stack[:len(stack)-1]
				}
			}
		}

		// After processing the error line, check if there's an unmatched opening bracket
		if i == closeLine && len(stack) > 0 {
			return stack[len(stack)-1].line
		}
	}

	return -1 // No matching bracket found
}
