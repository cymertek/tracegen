// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements tgfmt - MP language formatter with configuration support.
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/cymertek/tracegen/internal/formatter"
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
	case "format":
		formatCommand(args)
	case "check":
		checkCommand(args)
	case "version", "--version", "-V":
		fmt.Printf("tgfmt v%s\n", version)
	case "help", "--help", "-h":
		printUsage()
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n", command)
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`tgfmt - MP Language Formatter for CYMERTEK CUDA Trace Generator

Formats .mp files according to style rules with configurable options.

Usage:
  tgfmt <command> [arguments]

Commands:
  format    Format MP file(s) in-place or to stdout
      --config=FILE        Configuration file path (default: .tgfmt.yml)
      --indent=N           Indentation width in spaces (default: 4)
      --line-width=N       Maximum line width (default: 100)
      --comment-style=mp|c  Comment style: mp (* ... *) or c /* ... */ (default: mp)
      -w                     Write to file instead of stdout
      -v, --verbose        Show formatting details

  check     Check if files are properly formatted without modifying them
      --config=FILE        Configuration file path (default: .tgfmt.yml)
      --exit-code          Return non-zero exit code if files need formatting

  version   Display version information

Examples:
  tgfmt format model.mp -w
  tgfmt check *.mp --exit-code
  tgfmt format --config=my-style.yml --indent=2 *.mp`)
}

func formatCommand(args []string) {
	var (
		configFile string
		indent     int
		lineWidth  int
		commentStyle string
		writeToFile bool
		verbose    bool
		files      []string
	)

	fs := flag.NewFlagSet("format", flag.ExitOnError)
	fs.StringVar(&configFile, "config", ".tgfmt.yml", "Configuration file path")
	fs.IntVar(&indent, "indent", 4, "Indentation width in spaces")
	fs.IntVar(&lineWidth, "line-width", 100, "Maximum line width")
	fs.StringVar(&commentStyle, "comment-style", "mp", "Comment style: mp or c")
	fs.BoolVar(&writeToFile, "w", false, "Write to file instead of stdout")
	fs.BoolVar(&verbose, "v", false, "Show formatting details")

	_ = fs.Parse(args) // Ignore parse errors; flag.ExitOnError handles invalid flags
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: format command requires at least one .mp file")
		os.Exit(1)
	}

	config := formatter.LoadConfig(configFile)
	config.IndentWidth = indent
	config.LineWidth = lineWidth
	config.CommentStyle = commentStyle

	for _, file := range files {
		if err := formatFile(file, config, writeToFile, verbose); err != nil {
			fmt.Fprintf(os.Stderr, "Error formatting %s: %v\n", file, err)
			os.Exit(1)
		}
	}
}

func checkCommand(args []string) {
	var (
		configFile string
		exitCode   bool
		verbose    bool
		files      []string
	)

	fs := flag.NewFlagSet("check", flag.ExitOnError)
	fs.StringVar(&configFile, "config", ".tgfmt.yml", "Configuration file path")
	fs.BoolVar(&exitCode, "exit-code", false, "Return non-zero exit code if files need formatting")
	fs.BoolVar(&verbose, "v", false, "Show formatting details")

	_ = fs.Parse(args) // Ignore parse errors; flag.ExitOnError handles invalid flags
	files = fs.Args()

	if len(files) == 0 {
		fmt.Fprintln(os.Stderr, "Error: check command requires at least one .mp file")
		os.Exit(1)
	}

	config := formatter.LoadConfig(configFile)
	hasIssues := false

	for _, file := range files {
		isFormatted, err := checkFile(file, config)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error checking %s: %v\n", file, err)
			os.Exit(1)
		}
		if !isFormatted {
			hasIssues = true
			if verbose {
				fmt.Printf("%s: needs formatting\n", file)
			} else {
				fmt.Printf("%s\n", file)
			}
		}
	}

	if hasIssues && exitCode {
		os.Exit(1)
	}
}

func formatFile(filename string, config *formatter.Config, writeToFile bool, verbose bool) error {
	input, err := os.ReadFile(filename)
	if err != nil {
		return fmt.Errorf("reading %s: %w", filename, err)
	}

	formatted, err := formatter.Format(string(input), config)
	if err != nil {
		return fmt.Errorf("formatting %s: %w", filename, err)
	}

	outputPath := filename
	if !writeToFile {
		fmt.Print(formatted)
		return nil
	}

	baseName := filepath.Base(filename)
	dir := filepath.Dir(filename)
	ext := filepath.Ext(baseName)
	nameWithoutExt := strings.TrimSuffix(baseName, ext)

	// Preserve original extension or use .mp if not specified
	if ext == "" {
		outputPath = filepath.Join(dir, nameWithoutExt+".mp")
	}

	if err := os.WriteFile(outputPath, []byte(formatted), 0644); err != nil {
		return fmt.Errorf("writing %s: %w", outputPath, err)
	}

	if verbose {
		fmt.Printf("Formatted: %s -> %s\n", filename, outputPath)
	}

	return nil
}

func checkFile(filename string, config *formatter.Config) (bool, error) {
	input, err := os.ReadFile(filename)
	if err != nil {
		return false, fmt.Errorf("reading %s: %w", filename, err)
	}

	formatted, err := formatter.Format(string(input), config)
	if err != nil {
		return false, fmt.Errorf("formatting %s: %w", filename, err)
	}

	return string(input) == formatted, nil
}
