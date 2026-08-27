// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements tgeval — in-place evaluation of MP behavioral models without compilation.
package main

import (
	"encoding/json"
	"fmt"
	"flag"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync/atomic"
	"time"

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
      --progress         Enable progress updates every 2 seconds

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
		scope       int
		output      string
		quiet       bool
		verbose     bool
		progress    bool
		analyzeDeps bool
		files       []string
	)

	fs := flag.NewFlagSet("eval", flag.ExitOnError)
	fs.IntVar(&scope, "scope", 1, "Iteration scope (default: 1)")
	fs.StringVar(&output, "o", "", "Output file path (default: stdout)")
	fs.BoolVar(&quiet, "q", false, "Suppress progress messages")
	fs.BoolVar(&quiet, "quiet", false, "Suppress progress messages")
	fs.BoolVar(&verbose, "v", false, "Show detailed evaluation information")
	fs.BoolVar(&progress, "progress", false, "Show progress updates every 2 seconds (prefixed with #)")
	fs.BoolVar(&analyzeDeps, "analyze-deps", false, "Analyze coordinate dependencies and print summary")

	_ = fs.Parse(args)
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: eval command requires at least one .mp file")
		os.Exit(1)
	}

	for _, mpFile := range files {
		if err := evaluate(mpFile, scope, output, quiet, verbose, progress, analyzeDeps); err != nil {
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
func evaluate(mpFile string, scope int, outputPath string, quiet bool, verbose bool, showProgress bool, analyzeDeps bool) error {
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

	// Print dependency analysis if requested (before generation starts)
	if analyzeDeps && !quiet {
		generator.PrintDependencyAnalysis(schemaNode)
		fmt.Fprintln(os.Stderr) // Add blank line after analysis
	}
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

	// Flush any buffered records before querying count
	if err := dbStore.Flush(); err != nil {
		return fmt.Errorf("flushing trace store: %w", err)
	}

	uniqueCount, err := dbStore.QueryCount()
	if err != nil {
		return fmt.Errorf("querying trace count: %w", err)
	}
	totalInstances, _ := dbStore.TotalInstances()

	if !quiet {
		fmt.Fprintf(os.Stderr, "[INFO] Generated %d unique trace patterns (%d total instances)\n", uniqueCount, totalInstances)
	}

	// GC hint: free intermediate slices from generation before streaming output.
	runtime.GC()

	// Stream JSON output directly from SQLite cursor — no in-memory accumulation.
	var writer io.Writer = os.Stdout
	if outputPath != "" && outputPath != "-" {
		outputDir := filepath.Dir(outputPath)
		if outputDir != "." && outputDir != "" {
			if err := os.MkdirAll(outputDir, 0755); err != nil {
				return fmt.Errorf("creating output directory %s: %w", outputDir, err)
			}
		}
		f, err := os.Create(outputPath)
		if err != nil {
			return fmt.Errorf("opening output file %s: %w", outputPath, err)
		}
		defer f.Close()
		writer = f
	}

	sw := generator.NewStreamWriter(writer, 0) // unlimited traces

	// Start progress reporter if requested.
	var updateProgress func(count int64)
	if showProgress {
		flushFn := func() { _ = dbStore.Flush() }
		updateProgress = startProgressReporter(uniqueCount, flushFn)
	}

	if err := generator.StreamTracesToWriter(dbStore, sw, updateProgress); err != nil {
		return fmt.Errorf("streaming traces to output: %w", err)
	}

	// Flush progress reporter - wait for goroutine to print final status
	if showProgress {
		time.Sleep(2 * time.Second)
	}

	if outputPath != "" && outputPath != "-" && !quiet {
		fmt.Printf("%d unique traces written to %s\n", uniqueCount, outputPath)
	}

	return nil
}

// traceCount parses an MP file and returns the number of unique trace segments using SQLite dedup.
func traceCount(mpFile string, scope int) (int64, error) {
	fmt.Printf("[TRACE] Starting traceCount for %s scope=%d\n", mpFile, scope)
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

	dbStore, err := store.NewSQLiteStore(".")
	if err != nil {
		return 0, fmt.Errorf("creating SQLite store: %w", err)
	}
	defer dbStore.Close()

	if err := dbStore.ClearAll(); err != nil {
		return 0, fmt.Errorf("clearing trace store: %w", err)
	}

	if err := gen.GenerateTracesToSQLite(schemaNode, scope, dbStore); err != nil {
		return 0, fmt.Errorf("generating traces for %s: %w", mpFile, err)
	}

	// Flush buffered writes before querying count
	if err := dbStore.Flush(); err != nil {
		return 0, fmt.Errorf("flushing trace store: %w", err)
	}

	count, err := dbStore.QueryCount()
	if err != nil {
		return 0, fmt.Errorf("querying trace count: %w", err)
	}

	return count, nil
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

// startProgressReporter starts a background goroutine that prints progress every 2 seconds as JSON.
// Progress lines are prefixed with "# [PROGRESS] " followed by a JSON object.
// Format example: # [PROGRESS] {"seconds": 2.1, "done":6, "total":10, "perSecond": 10.7, "percent":60.3}
// startProgressReporter starts a background goroutine that prints progress every 2 seconds as JSON.
// Progress lines are prefixed with "# [PROGRESS] " followed by a JSON object.
// Format example: # [PROGRESS] {"seconds": 2.1, "done":6, "total":10, "perSecond": 10.7, "percent":60.3, "eta": "1h30m15s"}
func startProgressReporter(totalTraces int64, flushFn func()) func(int64) {
	var currentCount atomic.Int64
	var sampleIndex int64

	// Tape history for moving average (5 samples over ~10 seconds at 2s intervals)
	type sample struct {
		count int64
		time  time.Time
	}
	tape := make([]sample, 5)

	go func() {
		startTime := time.Now()
		ticker := time.NewTicker(2 * time.Second)
		defer ticker.Stop()

		for range ticker.C {
			count := currentCount.Load()
			if totalTraces > 0 && count > 0 {
				pct := float64(count) / float64(totalTraces) * 100
				elapsed := time.Since(startTime).Seconds()

				// Flush buffered writes to get accurate counts
				if flushFn != nil {
					flushFn()
				}

				// Calculate moving average rate using samples over ~10 seconds
				idx := int(sampleIndex % 5)
				prevIdx := int((sampleIndex - 4 + 5) % 5) // 4 samples back = ~8-10 seconds

				var rate float64
				if sampleIndex >= 4 && tape[prevIdx].time.Before(tape[idx].time) {
					delta := count - tape[prevIdx].count
					timeDiff := time.Since(tape[prevIdx].time).Seconds()
					if timeDiff > 0 {
						rate = float64(delta) / timeDiff
					}
				} else if sampleIndex >= 1 {
					// Use overall average for first few samples (after first progress update)
					elapsed := time.Since(startTime).Seconds()
					if elapsed > 0 {
						rate = float64(count) / elapsed
					}
				} else {
					// First sample - use instant rate from start
					elapsed := time.Since(startTime).Seconds()
					if elapsed > 0 {
						rate = float64(count) / elapsed
					}
				}

				// Calculate ETA based on rate and remaining traces
				var eta string
				if rate > 0 {
					remaining := int64(totalTraces - count)
					etaSeconds := float64(remaining) / rate
					etaDuration := time.Duration(etaSeconds * float64(time.Second))

					// Format as Go duration: "1h30m15s" or "30m15s" or "45s" or "0.5s"
					hours := int(etaDuration.Hours())
					minutes := int(etaDuration.Minutes()) % 60
					seconds := int(etaDuration.Seconds()) % 60

					if hours > 0 {
						eta = fmt.Sprintf("%dh%dm%ds", hours, minutes, seconds)
					} else if minutes > 0 {
						eta = fmt.Sprintf("%dm%ds", minutes, seconds)
					} else if etaDuration >= time.Second {
						eta = fmt.Sprintf("%.1fs", etaSeconds)
					} else {
						eta = "instant"
					}
				}

				// Format JSON with specific precision: 0.1 for most fields, 3 sig figs for perSecond
				if eta != "" {
					fmt.Fprintf(os.Stderr, "# [PROGRESS] {\"seconds\": %.1f, \"done\": %d, \"total\": %d, \"perSecond\": %.3g, \"percent\": %.1f, \"eta\": \"%s\"}\n",
						elapsed, count, totalTraces, rate, pct, eta)
				} else {
					fmt.Fprintf(os.Stderr, "# [PROGRESS] {\"seconds\": %.1f, \"done\": %d, \"total\": %d, \"perSecond\": %.3g, \"percent\": %.1f}\n",
						elapsed, count, totalTraces, rate, pct)
				}

				tape[idx] = sample{count: count, time: time.Now()}
				sampleIndex++
			} else if count > 0 {
				elapsed := time.Since(startTime).Seconds()
				fmt.Fprintf(os.Stderr, "# [PROGRESS] {\"seconds\": %.1f, \"done\": %d}\n", elapsed, count)
			}
		}
	}()

	return func(count int64) {
		currentCount.Store(count)
	}
}
