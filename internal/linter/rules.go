// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package linter

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// Rule5NoMagicNumbers detects hardcoded numeric literals that should be named constants.
var Rule5NoMagicNumbers = Rule{
	ID:          "no-magic-numbers",
	Description: "Extract hardcoded numeric values into named constants for clarity and maintainability.",
	Severity:    "warning",
	Check:       checkNoMagicNumbers,
	Example:     `price := 8; // Should be named constant like DefaultItemPrice`,
}

func checkNoMagicNumbers(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	numberPattern := regexp.MustCompile(`(?:(?:==|!=|<=|>=|=|\+=|-=|\*=|\/=)\s*)(-?\d+)`)

	for i, line := range lines {
		matches := numberPattern.FindAllStringSubmatch(line, -1)
		for _, match := range matches {
			if len(match) >= 2 {
				numStr := match[1]
				num, err := strconv.Atoi(numStr)
				if err != nil {
					continue
				}

				if num != 0 && num != 1 && num != -1 {
					col := strings.Index(line, match[0]) + 1
					violations = append(violations, Violation{
						File:    filename,
						Line:    i + 1,
						Column:  col,
						Message: fmt.Sprintf("Magic number %d found. Consider extracting to a named constant.", num),
						RuleID:  "no-magic-numbers",
					})
				}
			}
		}
	}

	return violations
}

// Rule6MaxFunctionLength prevents excessively long functions/blocks.
var Rule6MaxFunctionLength = Rule{
	ID:          "max-function-length",
	Description: "Keep functions and blocks under a reasonable length for readability.",
	Severity:    "warning",
	Check:       checkMaxFunctionLength,
	Example:     `BUILD { /* more than 100 lines of ENSURE statements */ };`,
}

func checkMaxFunctionLength(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")
	const maxLines = 100

	currentBlockStart := -1
	braceCount := 0

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "" || strings.HasPrefix(trimmed, "//") || strings.HasPrefix(trimmed, "(*") || strings.HasPrefix(trimmed, "/*") {
			continue
		}

		if braceCount == 0 && (strings.Contains(trimmed, ":=") || strings.Contains(trimmed, "=")) && !strings.HasPrefix(trimmed, "SCHEMA") && !strings.HasPrefix(trimmed, "ROOT") {
			currentBlockStart = i
		}

		for _, ch := range line {
			switch ch {
			case '{':
				braceCount++
			case '}':
				braceCount--
			}
		}

		if braceCount <= 0 && currentBlockStart >= 0 && i > currentBlockStart+maxLines {
			violations = append(violations, Violation{
				File:    filename,
				Line:    currentBlockStart + 1,
				Column:  1,
				Message: fmt.Sprintf("Function/block exceeds %d lines (currently at line %d). Consider refactoring.", maxLines, i+1),
				RuleID:  "max-function-length",
			})
			currentBlockStart = -1
		}
	}

	return violations
}

// Rule7NoDeadCode detects commented-out or unreachable code.
var Rule7NoDeadCode = Rule{
	ID:          "no-dead-code",
	Description: "Remove commented-out code blocks that are no longer needed.",
	Severity:    "info",
	Check:       checkNoDeadCode,
	Example:     `// $x := someOldVariable; // Dead code`,
}

func checkNoDeadCode(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if strings.HasPrefix(trimmed, "//") && len(trimmed) > 4 {
			body := strings.TrimSpace(trimmed[2:])
			// Skip nolint directives and standard markers
			isNolint := strings.Contains(body, "nolint:") || (strings.EqualFold(strings.Split(body, " ")[0], "nolint") && len(body) <= 7)
			if !isNolint && !strings.Contains(body, "TODO") && !strings.Contains(body, "FIXME") &&
				!strings.Contains(body, "NOTE") {
				violations = append(violations, Violation{
					File:    filename,
					Line:    i + 1,
					Column:  1,
					Message: fmt.Sprintf("Commented-out code detected. Consider removing or using version control: %s", body),
					RuleID:  "no-dead-code",
				})
			}
		}
	}

	return violations
}

// Rule8NamingConventions enforces consistent naming style for MP elements.
var Rule8NamingConventions = Rule{
	ID:          "naming-conventions",
	Description: "Event names should use camelCase or snake_case consistently.",
	Severity:    "info",
	Check:       checkNamingConventions,
	Example:     `ROOT CustomerName: (* event *); // Mixed case`,
}

func checkNamingConventions(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	for i, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "ROOT ") || strings.Contains(line, ":=") {
			parts := strings.Fields(line)
			for _, part := range parts {
				part = strings.Trim(part, ";:,(){}[]*+<>=!|")
				if len(part) > 1 && containsMixedCase(part) && !strings.HasPrefix(part, "$") {
					violations = append(violations, Violation{
						File:    filename,
						Line:    i + 1,
						Column:  strings.Index(line, part) + 1,
						Message: fmt.Sprintf("Event name '%s' uses mixed case. Consider using snake_case or camelCase consistently.", part),
						RuleID:  "naming-conventions",
					})
				}
			}
		}
	}

	return violations
}

func containsMixedCase(s string) bool {
	hasUpper := false
	hasLower := false
	for _, ch := range s {
		if ch >= 'A' && ch <= 'Z' {
			hasUpper = true
		} else if ch >= 'a' && ch <= 'z' {
			hasLower = true
		}
		if hasUpper && hasLower {
			return true
		}
	}
	return false
}

// Rule9MissingDocs requires documentation comments for rules and schemas.
var Rule9MissingDocs = Rule{
	ID:          "missing-docs",
	Description: "Add documentation comments explaining the purpose of schemas and complex rules.",
	Severity:    "info",
	Check:       checkMissingDocs,
	Example:     `SCHEMA MySchema // No comment above`,
}

func checkMissingDocs(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	inSchema := false
	hasDocBeforeSchema := false

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "" {
			continue
		}

		if strings.HasPrefix(trimmed, "SCHEMA ") && !hasDocBeforeSchema && i > 0 {
			violations = append(violations, Violation{
				File:    filename,
				Line:    i + 1,
				Column:  1,
				Message: "Missing documentation comment before SCHEMA declaration. Add a comment explaining the purpose of this schema.",
				RuleID:  "missing-docs",
			})
		}

		if strings.HasPrefix(trimmed, "//") || strings.HasPrefix(trimmed, "(*") || strings.HasPrefix(trimmed, "/*") {
			hasDocBeforeSchema = true
		}

		if strings.HasPrefix(trimmed, "SCHEMA ") {
			inSchema = true
			hasDocBeforeSchema = false
		}

		if strings.HasPrefix(trimmed, "END SCHEMA") || trimmed == ";" && inSchema {
			inSchema = false
		}
	}

	return violations
}

// Rule10CommentStyleConsistency enforces consistent comment style within a file.
var Rule10CommentStyleConsistency = Rule{
	ID:          "comment-style-consistency",
	Description: "Use consistent comment styles (/* */ or (* *)) throughout the file.",
	Severity:    "warning",
	Check:       checkCommentStyleConsistency,
	Example:     `// Mix of /* C-style */ and (* MP-style *) comments`,
}

func checkCommentStyleConsistency(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	hasCStyle := false  // /* */
	hasMPStyle := false // (* *)

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		if strings.HasPrefix(trimmed, "/*") && !strings.Contains(trimmed, "*┬") && !strings.Contains(trimmed, "│*│") {
			hasCStyle = true
		} else if strings.HasPrefix(trimmed, "(*") {
			hasMPStyle = true
		}
	}

	if hasCStyle && hasMPStyle {
		violations = append(violations, Violation{
			File:    filename,
			Line:    1,
			Column:  1,
			Message: "Mixed comment styles detected (/* */ and (* *)). Choose one style for consistency.",
			RuleID:  "comment-style-consistency",
		})
	}

	return violations
}

// Rule11DeclarationOrdering enforces SCHEMA → ROOT/RULE → COORDINATE → ATTRIBUTES ordering.
var Rule11DeclarationOrdering = Rule{
	ID:          "declaration-ordering",
	Description: "Maintain consistent declaration order: SCHEMA, then ROOT/RULE, then COORDINATE, then ATTRIBUTES.",
	Severity:    "warning",
	Check:       checkDeclarationOrdering,
	Example:     `ATTRIBUTES { ... }; // Should appear after COORDINATE blocks`,
}

func checkDeclarationOrdering(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	sectionOrder := map[string]int{
		"SCHEMA":     0,
		"ROOT":       1,
		"RULE":       1,
		"COORDINATE": 2,
		"ATTRIBUTES": 3,
	}

	lastSectionIdx := -1

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "" || strings.HasPrefix(trimmed, "//") || strings.HasPrefix(trimmed, "(*") || strings.HasPrefix(trimmed, "/*") {
			continue
		}

		for keyword, idx := range sectionOrder {
			if strings.HasPrefix(trimmed, keyword+" ") || strings.HasPrefix(trimmed, keyword+"\t") || trimmed == keyword+":" {
				if idx < lastSectionIdx {
					violations = append(violations, Violation{
						File:    filename,
						Line:    i + 1,
						Column:  1,
						Message: fmt.Sprintf("Declaration '%s' appears after later section. Expected order: SCHEMA → ROOT/RULE → COORDINATE → ATTRIBUTES.", keyword),
						RuleID:  "declaration-ordering",
					})
				}
				lastSectionIdx = idx
				break
			}
		}
	}

	return violations
}

// Rule12DuplicateRuleNames detects duplicate ROOT or RULE names within a schema.
var Rule12DuplicateRuleNames = Rule{
	ID:          "duplicate-rule-names",
	Description: "Prevent duplicate rule names within the same SCHEMA.",
	Severity:    "error",
	Check:       checkDuplicateRuleNames,
	Example:     `ROOT MyRule: (* event *); // First declaration\nROOT MyRule: (* different *); // Duplicate!`,
}

func checkDuplicateRuleNames(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	ruleNames := make(map[string]int)
	inSchema := false

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "" {
			continue
		}

		if strings.HasPrefix(trimmed, "SCHEMA ") {
			inSchema = true
			ruleNames = make(map[string]int) // Reset for new schema
			continue
		}

		if !inSchema {
			continue
		}

		if strings.HasPrefix(trimmed, "ROOT ") || strings.HasPrefix(trimmed, "RULE ") {
			parts := strings.Fields(trimmed)
			if len(parts) >= 2 {
				name := parts[1]
				// Remove colon if present
				name = strings.TrimSuffix(name, ":")

				ruleNames[name]++
				if ruleNames[name] > 1 {
					violations = append(violations, Violation{
						File:    filename,
						Line:    i + 1,
						Column:  1,
						Message: fmt.Sprintf("Duplicate rule name '%s' found. Each rule must have a unique name.", name),
						RuleID:  "duplicate-rule-names",
					})
				}
			}
		}

		if strings.HasPrefix(trimmed, "END SCHEMA") || (trimmed == ";" && len(ruleNames) > 0) {
			inSchema = false
		}
	}

	return violations
}

// Rule13ColonSpacingInRoot enforces single space after colon in ROOT declarations.
var Rule13ColonSpacingInRoot = Rule{
	ID:          "colon-spacing-in-root",
	Description: "Ensure consistent spacing after colon in ROOT declarations (e.g., 'ROOT Name: (*event*)').",
	Severity:    "warning",
	Check:       checkColonSpacingInRoot,
	Example:     `ROOT MyRule:(* event *); // Missing space after colon`,
}

func checkColonSpacingInRoot(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	for i, line := range lines {
		trimmed := strings.TrimSpace(line)

		if !strings.HasPrefix(trimmed, "ROOT ") {
			continue
		}

		// Check for colon followed by content (not a standalone ROOT declaration)
		colonIdx := strings.Index(trimmed, ":")
		if colonIdx == -1 || colonIdx == len(trimmed)-1 {
			continue // No colon or colon at end of line (standalone ROOT)
		}

		// Check what follows the colon
		afterColon := trimmed[colonIdx+1:]
		if len(afterColon) > 0 && !strings.HasPrefix(afterColon, " ") {
			violations = append(violations, Violation{
				File:    filename,
				Line:    i + 1,
				Column:  colonIdx + 2,
				Message: fmt.Sprintf("Missing space after colon in ROOT declaration. Use 'ROOT Name: (*event*)' not 'ROOT Name:%s'.", trimmed[colonIdx+1:]),
				RuleID:  "colon-spacing-in-root",
			})
		}
	}

	return violations
}

// Rule14ProbabilityAnnotationFormatting validates <<0.75>> format with no spaces.
var Rule14ProbabilityAnnotationFormatting = Rule{
	ID:          "probability-annotation-formatting",
	Description: "Ensure probability annotations use consistent formatting (e.g., <<0.75>> not << 0.75 >>).",
	Severity:    "warning",
	Check:       checkProbabilityAnnotationFormatting,
	Example:     `ROOT MyRule: (* << 0.75 >> push | pop *); // Spaces inside annotation`,
}

func checkProbabilityAnnotationFormatting(content string, filename string) []Violation {
	var violations []Violation
	lines := strings.Split(content, "\n")

	for i, line := range lines {
		if !strings.Contains(line, "<<") || !strings.Contains(line, ">>") {
			continue
		}

		// Find probability annotations - check the full match for spaces
		re := regexp.MustCompile(`<<([^>]*)>>`)
		matches := re.FindAllStringSubmatch(line, -1)

		for _, match := range matches {
			if len(match) >= 2 {
				fullContent := match[1]
				// Check if there are spaces or tabs inside the annotation (between << and >>)
				if strings.Contains(fullContent, " ") || strings.Contains(fullContent, "\t") {
					violations = append(violations, Violation{
						File:    filename,
						Line:    i + 1,
						Column:  strings.Index(line, match[0]) + 1,
						Message: fmt.Sprintf("Probability annotation has spaces inside. Use '<<%s>>' not '<< %s >>'.", fullContent, fullContent),
						RuleID:  "probability-annotation-formatting",
					})
				}
			}
		}
	}

	return violations
}

// AllRules returns all registered linting rules.
func AllRules() []Rule {
	return []Rule{
		Rule5NoMagicNumbers,
		Rule6MaxFunctionLength,
		Rule7NoDeadCode,
		Rule8NamingConventions,
		Rule9MissingDocs,
		Rule10CommentStyleConsistency,
		Rule11DeclarationOrdering,
		Rule12DuplicateRuleNames,
		Rule13ColonSpacingInRoot,
		Rule14ProbabilityAnnotationFormatting,
	}
}
