// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements tgeval — in-place evaluation of MP behavioral models without compilation.
package main

import (
	"encoding/json"
	"fmt"
	"flag"
	"os"
	"path/filepath"
	"strings"

	"github.com/cymertek/tracegen/internal/generator"
	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

const version = "1.0.0"

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]
	args := os.Args[2:]

	switch command {
	case "eval", "trace":
		evalCommand(args)
	case "count":
		countCommand(args)
	case "summary":
		summaryCommand(args)
	case "version", "--version", "-V":
		fmt.Printf("tgeval v%s\n", version)
	case "help", "--help", "-h":
		printUsage()
	default:
		// If first arg looks like an .mp file, treat as eval <file>
		if strings.HasSuffix(command, ".mp") {
			evalCommand(append([]string{command}, args...))
			return
		}
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`tgeval - In-place MP Behavioral Model Evaluator for CYMERTEK Trace Generator

Evaluates .mp files and generates traces directly on CPU without CUDA compilation.
Fast iteration for model development, testing, and validation.

Usage:
  tgeval <command> [arguments]

Commands:
  eval     Evaluate an MP file and output trace segments as JSON
      --scope=N          Iteration scope (default: 1)
      -s N               Short form of --scope
      -o FILE            Output file path (default: stdout)
      -q, --quiet        Suppress progress messages
      -v, --verbose      Show detailed evaluation information

      All evaluations use SQLite-backed streaming with automatic deduplication.

  count    Count trace segments produced by an MP file (fast, no JSON output)
      --scope=N          Iteration scope (default: 1)
      -s N               Short form of --scope
      -q, --quiet        Suppress progress messages

  summary  Print a concise summary of evaluated traces
      --scope=N          Iteration scope (default: 1)
      -s N               Short form of --scope
      -o FILE            Output file path (default: stdout)
      -q, --quiet        Suppress progress messages
      -v, --verbose      Show detailed summary information

  version  Display version information

Examples:
  tgeval eval model.mp                       # Output traces to stdout
  tgeval eval --scope=2 model.mp > traces.json
  tgeval count Example01_simple_message_flow.mp
  tgeval summary --verbose model.mp          # Show trace statistics
  tgeval model.mp                            # Same as: tgeval eval model.mp`)
}

// evalCommand handles "tgeval eval <file.mp>".
func evalCommand(args []string) {
	var (
		scope   int
		output  string
		quiet   bool
		verbose bool
		files   []string
	)

	fs := flag.NewFlagSet("eval", flag.ExitOnError)
	fs.IntVar(&scope, "scope", 1, "Iteration scope (default: 1)")
	fs.StringVar(&output, "o", "", "Output file path (default: stdout)")
	fs.BoolVar(&quiet, "q", false, "Suppress progress messages")
	fs.BoolVar(&quiet, "quiet", false, "Suppress progress messages")
	fs.BoolVar(&verbose, "v", false, "Show detailed evaluation information")

	_ = fs.Parse(args)
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: eval command requires at least one .mp file")
		os.Exit(1)
	}

	for _, mpFile := range files {
		if err := evaluate(mpFile, scope, output, quiet, verbose); err != nil {
			fmt.Fprintf(os.Stderr, "Error evaluating %s: %v\n", mpFile, err)
			os.Exit(1)
		}
	}
}

// countCommand handles "tgeval count <file.mp>".
func countCommand(args []string) {
	var (
		scope   int
		quiet   bool
		files   []string
	)

	fs := flag.NewFlagSet("count", flag.ExitOnError)
	fs.IntVar(&scope, "scope", 1, "Iteration scope (default: 1)")
	fs.BoolVar(&quiet, "q", false, "Suppress progress messages")
	fs.BoolVar(&quiet, "quiet", false, "Suppress progress messages")

	_ = fs.Parse(args)
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: count command requires at least one .mp file")
		os.Exit(1)
	}

	for _, mpFile := range files {
		count, err := traceCount(mpFile, scope)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error counting traces for %s: %v\n", mpFile, err)
			os.Exit(1)
		}
		if quiet {
			fmt.Printf("%d\n", count)
		} else {
			fmt.Println(count)
		}
	}
}

// summaryCommand handles "tgeval summary <file.mp>".
func summaryCommand(args []string) {
	var (
		scope   int
		output  string
		quiet   bool
		verbose bool
		files   []string
	)

	fs := flag.NewFlagSet("summary", flag.ExitOnError)
	fs.IntVar(&scope, "scope", 1, "Iteration scope (default: 1)")
	fs.StringVar(&output, "o", "", "Output file path (default: stdout)")
	fs.BoolVar(&quiet, "q", false, "Suppress progress messages")
	fs.BoolVar(&quiet, "quiet", false, "Suppress progress messages")
	fs.BoolVar(&verbose, "v", false, "Show detailed summary information")

	_ = fs.Parse(args)
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: summary command requires at least one .mp file")
		os.Exit(1)
	}

	for _, mpFile := range files {
		if err := evaluateSummary(mpFile, scope, output, quiet, verbose); err != nil {
			fmt.Fprintf(os.Stderr, "Error summarizing traces for %s: %v\n", mpFile, err)
			os.Exit(1)
		}
	}
}

// evaluate parses an MP file and generates trace segments via SQLite-backed streaming.
func evaluate(mpFile string, scope int, outputPath string, quiet bool, verbose bool) error {
	input, err := os.ReadFile(mpFile)
	if err != nil {
		return fmt.Errorf("reading %s: %w", mpFile, err)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		return fmt.Errorf("tokenizing %s: %w", mpFile, err)
	}

	schemaNode, err := parser.NewParser(tokens).Parse()
	if err != nil {
		return fmt.Errorf("parsing %s: %w", mpFile, err)
	}

	if verbose && !quiet {
		fmt.Fprintf(os.Stderr, "[INFO] Parsed schema %q: %d roots, %d rules, %d coordinates\n",
			schemaNode.Name, len(schemaNode.Rules), len(schemaNode.Rules), len(schemaNode.Coordinates))
		for _, rule := range schemaNode.Rules {
			if rule.IsRoot {
				fmt.Fprintf(os.Stderr, "[INFO]   ROOT: %s (%d patterns)\n", rule.Name, len(rule.PatternList))
			}
		}
	}

	gen := generator.NewCPUGenerator(0) // scope handled at generation time

	// Create SQLite store for deduplication (lives in .tgrun_cache/ next to executable).
	dbStore, err := store.NewSQLiteStore(".")
	if err != nil {
		return fmt.Errorf("creating SQLite store: %w", err)
	}
	defer dbStore.Close()

	// Clear any previous traces from this store (idempotent for fresh runs).
	if err := dbStore.ClearAll(); err != nil {
		return fmt.Errorf("clearing trace store: %w", err)
	}

	// Stream generation directly to SQLite — no in-memory accumulation.
	if err := gen.GenerateTracesToSQLite(schemaNode, scope, dbStore); err != nil {
		return fmt.Errorf("generating traces for %s: %w", mpFile, err)
	}

	uniqueCount, _ := dbStore.TotalTraces()
	totalInstances, _ := dbStore.TotalInstances()

	if !quiet {
		fmt.Fprintf(os.Stderr, "[INFO] Generated %d unique trace patterns (%d total instances)\n", uniqueCount, totalInstances)
	}

	// Produce pretty-printed JSON output from SQLite (matches C++ format exactly).
	jsonOutput, err := generator.MarshalToJSONFromStore(dbStore)
	if err != nil {
		return fmt.Errorf("marshaling traces to JSON: %w", err)
	}

	if outputPath == "" || outputPath == "-" {
		fmt.Print(jsonOutput)
	} else {
		outputDir := filepath.Dir(outputPath)
		if outputDir != "." && outputDir != "" {
			if err := os.MkdirAll(outputDir, 0755); err != nil {
				return fmt.Errorf("creating output directory %s: %w", outputDir, err)
			}
		}
		if err := os.WriteFile(outputPath, []byte(jsonOutput), 0644); err != nil {
			return fmt.Errorf("writing output to %s: %w", outputPath, err)
		}
		if !quiet {
			fmt.Printf("%d unique traces written to %s\n", uniqueCount, outputPath)
		}
	}

	return nil
}

// traceCount parses an MP file and returns the number of trace segments without marshaling JSON.
func traceCount(mpFile string, scope int) (int, error) {
	input, err := os.ReadFile(mpFile)
	if err != nil {
		return 0, fmt.Errorf("reading %s: %w", mpFile, err)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		return 0, fmt.Errorf("tokenizing %s: %w", mpFile, err)
	}

	schemaNode, err := parser.NewParser(tokens).Parse()
	if err != nil {
		return 0, fmt.Errorf("parsing %s: %w", mpFile, err)
	}

	gen := generator.NewCPUGenerator(0)
	traces, err := gen.GenerateTraces(schemaNode, scope)
	if err != nil {
		return 0, fmt.Errorf("generating traces for %s: %w", mpFile, err)
	}

	return len(traces), nil
}

// evaluateSummary generates a text summary of trace statistics.
func evaluateSummary(mpFile string, scope int, outputPath string, quiet bool, _ bool) error {
	input, err := os.ReadFile(mpFile)
	if err != nil {
		return fmt.Errorf("reading %s: %w", mpFile, err)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		return fmt.Errorf("tokenizing %s: %w", mpFile, err)
	}

	schemaNode, err := parser.NewParser(tokens).Parse()
	if err != nil {
		return fmt.Errorf("parsing %s: %w", mpFile, err)
	}

	gen := generator.NewCPUGenerator(0)
	traces, err := gen.GenerateTraces(schemaNode, scope)
	if err != nil {
		return fmt.Errorf("generating traces for %s: %w", mpFile, err)
	}

	summary := buildSummary(traces, schemaNode.Name, scope)

	jsonOutput, err := json.MarshalIndent(summary, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling summary: %w", err)
	}

	if outputPath == "" || outputPath == "-" {
		fmt.Println(string(jsonOutput))
	} else {
		outputDir := filepath.Dir(outputPath)
		if outputDir != "." && outputDir != "" {
			if err := os.MkdirAll(outputDir, 0755); err != nil {
				return fmt.Errorf("creating output directory %s: %w", outputDir, err)
			}
		}
		if err := os.WriteFile(outputPath, jsonOutput, 0644); err != nil {
			return fmt.Errorf("writing summary to %s: %w", outputPath, err)
		}
		if !quiet {
			fmt.Printf("%d trace segments summarized -> %s\n", len(traces), outputPath)
		}
	}

	return nil
}

// traceSummary holds computed statistics about generated traces.
type traceSummary struct {
	SchemaName  string `json:"schema_name"`
	Scope       int    `json:"scope"`
	TotalTraces int    `json:"total_traces"`
	Marked      int    `json:"marked"`
	Unmarked    int    `json:"unmarked"`
	MaxEvents   int    `json:"max_events"`
	AvgEvents   float64 `json:"avg_events"`
	RootsUsed   []string  `json:"roots_used,omitempty"`
}

// buildSummary computes trace statistics from generated segments.
func buildSummary(traces []generator.TraceSegment, schemaName string, scope int) traceSummary {
	sum := traceSummary{
		SchemaName:  schemaName,
		Scope:       scope,
		TotalTraces: len(traces),
	}

	totalEvents := 0
	for _, seg := range traces {
		if seg.MarkStatus == "M" {
			sum.Marked++
		} else {
			sum.Unmarked++
		}

		eventCount := len(seg.Events)
		totalEvents += eventCount
		if eventCount > sum.MaxEvents {
			sum.MaxEvents = eventCount
		}
	}

	if sum.TotalTraces > 0 {
		sum.AvgEvents = float64(totalEvents) / float64(sum.TotalTraces)
	}

	return sum
}
