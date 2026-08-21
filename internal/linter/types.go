// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package linter implements MP language linting with pluggable rules.
package linter

import "fmt"

// Violation represents a single linting violation found in an MP file.
type Violation struct {
	File    string
	Line    int
	Column  int
	Message string
	RuleID  string
}

func (v Violation) String() string {
	return fmt.Sprintf("%s:%d:%d: [%s] %s", v.File, v.Line, v.Column, v.RuleID, v.Message)
}

// Rule defines a linting rule with metadata and check logic.
type Rule struct {
	ID          string // Descriptive ID like "no-magic-numbers" (used for suppression matching)
	Number      string // A-prefixed number like "A001" (for display only)
	Description string
	Severity    string // "error", "warning", "info"
	Check       func(content string, filename string) []Violation
	Example     string // Example violation message
}

// RuleConfig holds per-rule settings and severity overrides.
type RuleConfig struct {
	Disabled bool              `yaml:"disabled"`
	Severity string            `yaml:"severity"` // "error", "warning", "info"
	Options  map[string]any    `yaml:"options"`
}

// Config represents the tglint configuration file structure and runtime settings.
type Config struct {
	Rules         map[string]RuleConfig
	SelectedRules []string
	Severity      string
	Verbose       bool
	Quiet         bool
}
