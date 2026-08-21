// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements tglint - MP language linter with configurable rules and suppression support.
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/cymertek/tracegen/internal/linter"
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
	case "lint":
		lintCommand(args)
	case "list-rules":
		listRulesCommand()
	case "version", "--version", "-V":
		fmt.Printf("tglint v%s\n", version)
	case "help", "--help", "-h":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`tglint - MP Language Linter for CYMERTEK CUDA Trace Generator

Checks .mp files against configurable linting rules with suppression support.

Usage:
  tglint <command> [arguments]

Commands:
  lint         Run linter on MP file(s)
      --config=FILE        Configuration file path (default: .tglint.yml)
      --rules=rule1,rule2  Specific rules to check by ID or number (default: all)
      --severity=warning   Minimum severity: error, warning, info (default: info)
      -v, --verbose        Show detailed rule descriptions
      -q, --quiet          Only show violations

  list-rules   List all available linting rules with numbers

  version      Display version information

Suppression Syntax:
  Add "// nolint:rule-id" or "// nolint:A001" comments to suppress specific rules.
  Use "// nolint" alone to suppress all rules on the next line.

Configuration File (.tglint.yml):
  rules:
    no-magic-numbers:
      disabled: false
      severity: warning
    max-function-length:
      options:
        max_lines: 100

Examples:
  tglint lint model.mp
  tglint lint --config=my-config.yml model.mp
  tglint lint --rules=A001,A002 *.mp
  tglint list-rules`)
}

func lintCommand(args []string) {
	var (
		configFlag string
		rulesFlag  string
		severity   string
		verbose    bool
		quiet      bool
		files      []string
	)

	fs := flag.NewFlagSet("lint", flag.ContinueOnError)
	fs.StringVar(&configFlag, "config", "", "Configuration file path (default: .tglint.yml)")
	fs.StringVar(&rulesFlag, "rules", "", "Comma-separated list of rules to check by ID or number")
	fs.StringVar(&severity, "severity", "info", "Minimum severity: error, warning, info")
	fs.BoolVar(&verbose, "v", false, "Show detailed rule descriptions")
	fs.BoolVar(&quiet, "q", false, "Only show violations")

	if err := fs.Parse(args); err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing flags: %v\n", err)
		os.Exit(1)
	}
	files = fs.Args()

	// Filter out any remaining flag-like arguments (shouldn't happen with ContinueOnError)
	var cleanFiles []string
	for _, f := range files {
		if !strings.HasPrefix(f, "-") {
			cleanFiles = append(cleanFiles, f)
		}
	}
	files = cleanFiles

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: lint command requires at least one .mp file")
		os.Exit(1)
	}

	// Parse rules filter
	var selectedRules []string
	if rulesFlag != "" {
		selectedRules = strings.Split(rulesFlag, ",")
		for i := range selectedRules {
			selectedRules[i] = strings.TrimSpace(selectedRules[i])
		}
	}

	// Load configuration file if specified or default exists
	config := linter.DefaultConfig()
	if configFlag != "" || fileExists(".tglint.yml") {
		cfgPath := ".tglint.yml"
		if configFlag != "" {
			cfgPath = configFlag
		}
		loaded, err := linter.LoadConfig(cfgPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: could not load config %s: %v\n", cfgPath, err)
		} else {
			config = loaded
		}
	}

	config.SelectedRules = selectedRules
	config.Severity = severity
	config.Verbose = verbose
	config.Quiet = quiet

	violations, err := linter.RunLinter(files, config)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error running linter: %v\n", err)
		os.Exit(1)
	}

	if !quiet {
		printViolationSummary(violations, verbose)
	} else {
		for _, v := range violations {
			fmt.Printf("%s:%d:%d: %s [%s]\n", v.File, v.Line, v.Column, v.Message, v.RuleID)
		}
	}

	if len(violations) > 0 {
		os.Exit(1)
	}
}

func listRulesCommand() {
	rules := linter.ListAllRules()

	fmt.Println("Available linting rules:")
	fmt.Println(strings.Repeat("-", 80))

	for _, rule := range rules {
		idDisplay := rule.ID
		if rule.Number != "" {
			idDisplay = fmt.Sprintf("%s (%s)", rule.Number, rule.ID)
		}
		fmt.Printf("\n%s (%s)\n", idDisplay, strings.ToUpper(rule.Severity))
		fmt.Printf("  Description: %s\n", rule.Description)
		if rule.Example != "" {
			fmt.Printf("  Example:\n    %s\n", rule.Example)
		}
	}

	fmt.Println(strings.Repeat("-", 80))
	fmt.Printf("\nTotal rules: %d\n", len(rules))
}

func printViolationSummary(violations []linter.Violation, verbose bool) {
	if len(violations) == 0 {
		fmt.Println("No violations found. ✓")
		return
	}

	fmt.Printf("\nFound %d violation(s):\n\n", len(violations))

	for _, v := range violations {
		fmt.Printf("%s:%d:%d: [%s] %s\n", v.File, v.Line, v.Column, strings.ToUpper(v.RuleID), v.Message)
	}

	if verbose {
		fmt.Println("\nTo suppress a violation, add a comment before the violating line:")
		fmt.Println("  // nolint:A001    # Suppress specific rule by number")
		fmt.Println("  // nolint:no-magic-numbers  # Suppress by ID")
		fmt.Println("  // nolint         # Suppress all rules on next line")
	}
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
