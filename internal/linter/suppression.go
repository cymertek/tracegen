// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package linter

import (
	"regexp"
	"strings"
)

// Suppression represents a nolint comment suppression directive.
type Suppression struct {
	RuleIDs []string // List of rule IDs to suppress (empty means all rules)
}

// ParseSuppressionComments scans the content for "// nolint:" comments and returns supressions per line.
func ParseSuppressionComments(content string) map[int]Suppression {
	suppressions := make(map[int]Suppression)
	lines := strings.Split(content, "\n")

	// Regex to find nolint directives anywhere in a line (case-insensitive)
	// Matches "// nolint:A001", "// nolint:no-magic-numbers", "// nolint" (bare), etc.
	nolintPattern := regexp.MustCompile(`(?i)(?:^|[^a-zA-Z0-9_])nolint\s*(?::\s*(.*))?\s*$`)

	for i, line := range lines {
		matches := nolintPattern.FindAllStringSubmatch(line, -1)

		if len(matches) == 0 {
			continue
		}

		for _, match := range matches {
			directive := strings.TrimSpace(match[len(match)-1]) // Last capture group is the directive
			// Strip inline comments (text after " - " or " -- ")
			if idx := strings.Index(directive, " - "); idx != -1 {
				directive = directive[:idx]
			} else if idx := strings.Index(directive, " --"); idx != -1 {
				directive = directive[:idx]
			}

			suppression := Suppression{}

			if directive == "" || strings.EqualFold(directive, "all") || strings.EqualFold(directive, "*") {
				suppression.RuleIDs = []string{} // Empty slice means suppress all rules
			} else {
				parts := strings.Split(directive, ",")
				for _, part := range parts {
					part = strings.TrimSpace(part)
					if part != "" && !strings.HasPrefix(part, "//") && !strings.HasPrefix(part, "/*") {
						suppression.RuleIDs = append(suppression.RuleIDs, part)
					}
				}
			}

			suppressions[i+1] = suppression // 1-indexed line numbers
		}
	}

	return suppressions
}

// IsSuppressed checks if a violation at the given line should be suppressed by a nolint comment.
func IsSuppressed(violationLine int, ruleID string, suppressions map[int]Suppression) bool {
	// Check current line and previous line for suppression comments
	for _, checkLine := range []int{violationLine, violationLine - 1} {
		sup, exists := suppressions[checkLine]
		if !exists {
			continue
		}

		// If suppression has no specific rules (empty slice), it suppresses all
		if len(sup.RuleIDs) == 0 {
			return true
		}

		// Check if this specific rule is in the suppression list
		for _, id := range sup.RuleIDs {
			if strings.EqualFold(id, ruleID) {
				return true
			}
		}
	}

	return false
}
