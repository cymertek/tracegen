// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package linter

import (
	"fmt"
	"os"
	"strings"
)

// Rule numbering map for ID to number conversion.
var ruleNumberMap = map[string]string{
	"no-magic-numbers":                    "A001",
	"max-function-length":                 "A002",
	"no-dead-code":                        "A003",
	"naming-conventions":                  "A004",
	"missing-docs":                        "A005",
	"comment-style-consistency":           "A006",
	"declaration-ordering":                "A007",
	"duplicate-rule-names":                "A008",
	"colon-spacing-in-root":               "A009",
	"probability-annotation-formatting":   "A010",
}

// Reverse map for rule number to ID conversion.
var reverseRuleNumberMap = func() map[string]string {
	m := make(map[string]string)
	for name, num := range ruleNumberMap {
		m[num] = name
	}
	return m
}()

// RunLinter executes all configured linting rules on the given files.
func RunLinter(files []string, config *Config) ([]Violation, error) {
	var allViolations []Violation

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return nil, fmt.Errorf("reading %s: %w", file, err)
		}

		violations := checkFile(string(content), file, config)
		allViolations = append(allViolations, violations...)
	}

	return allViolations, nil
}

// ListAllRules returns metadata for all registered rules with numbering.
func ListAllRules() []Rule {
	rules := AllRules()
	for i := range rules {
		if rules[i].ID == "" {
			continue
		}
		// Assign rule numbers based on registration order (A001, A002, etc.)
		ruleNum := fmt.Sprintf("A%03d", i+1)
		rules[i] = Rule{
			ID:          rules[i].ID, // Preserve original descriptive ID for suppression matching
			Number:      ruleNum,     // Set A-prefixed number for display
			Description: rules[i].Description,
			Severity:    applyConfigSeverity(&rules[i], nil),
			Check:       rules[i].Check,
			Example:     rules[i].Example,
		}
	}
	return rules
}

func checkFile(content string, filename string, config *Config) []Violation {
	var violations []Violation

	// Parse nolint suppression comments
	suppressions := ParseSuppressionComments(content)

	for _, rule := range AllRules() {
		// Skip if specific rules requested and this one not in list (by ID or number)
		if len(config.SelectedRules) > 0 && !containsRule(config.SelectedRules, rule.ID) {
			continue
		}

		// Check if rule is disabled via config
		if config.IsRuleDisabled(rule.ID) || config.IsRuleDisabled(extractRuleName(rule)) {
			continue
		}

		// Apply severity override from config
		sev := applyConfigSeverity(&rule, config)
		rule.Severity = sev

		// Skip if severity below threshold
		if !matchesSeverity(sev, config.Severity) {
			continue
		}

		v := rule.Check(content, filename)

		// Filter out suppressed violations (keep original RuleID in violation)
		for _, violation := range v {
			if !isViolationSuppressed(violation.Line, violation.RuleID, suppressions) {
				violations = append(violations, violation)
			}
		}
	}

	return violations
}

// isViolationSuppressed checks if a specific violation should be suppressed.
func isViolationSuppressed(line int, ruleID string, suppressions map[int]Suppression) bool {
	for checkLine := line - 1; checkLine <= line+1; checkLine++ {
		sup, exists := suppressions[checkLine]
		if !exists {
			continue
		}

		// Empty RuleIDs means suppress all rules
		if len(sup.RuleIDs) == 0 {
			return true
		}

		// Check if this rule ID or its number is in the suppression list
		for _, id := range sup.RuleIDs {
			if strings.EqualFold(id, ruleID) || strings.EqualFold(ruleNumberMap[ruleID], id) {
				return true
			}
		}
	}

	return false
}

func extractRuleName(rule Rule) string {
	// Extract rule name from ID (e.g., "no-dead-code" from "A003")
	if id := rule.ID; len(id) > 4 && id[:1] == "A" {
		// If it's a numbered rule, look up the original name from reverse map
		if name, ok := reverseRuleNumberMap[id]; ok {
			return name
		}
	}
	return rule.ID
}

func applyConfigSeverity(rule *Rule, config *Config) string {
	// Check for explicit severity override in config
	if config != nil {
		if override := config.GetSeverityOverride(rule.ID); override != "" {
			rule.Severity = override
			return override
		}
	}
	return rule.Severity
}

func containsRule(rules []string, target string) bool {
	for _, r := range rules {
		r = strings.TrimSpace(r)
		if r == target || strings.EqualFold(r, target) {
			return true
		}
	}
	return false
}

// matchesSeverity checks if rule severity meets minimum threshold.
// Priority: error > warning > info
func matchesSeverity(ruleSev, minSev string) bool {
	priority := map[string]int{
		"error":   3,
		"warning": 2,
		"info":    1,
	}

	rulePriority := priority[ruleSev]
	minPriority := priority[minSev]

	return rulePriority >= minPriority
}
