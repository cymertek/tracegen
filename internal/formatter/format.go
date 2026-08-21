// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package formatter

import (
	"strings"
)

// Format formats MP source code according to the given configuration.
func Format(input string, config *Config) (string, error) {
	lines := strings.Split(input, "\n")
	var formatted []string

	nestingDepth := 0 // Track nesting depth for proper indentation
	consecutiveBlanks := 0 // Track consecutive blank lines for MaxBlankLines enforcement
	pendingPipe := false // Flag: previous line ended with | and has unclosed parens

	// Track whether previous non-blank line was a declaration ending with ":" (sub-rule continuation)
	prevWasDeclaration := false
	hadUnclosedBracketDepth := false // Whether any entry so far had unmatched bracket depth > 0

	for i := 0; i < len(lines); {
		line := lines[i]
		trimmed := strings.TrimSpace(line)

		// Handle blank lines — enforce MaxBlankLines and pipe continuations
		if trimmed == "" {
			consecutiveBlanks++
			if config.MaxBlankLines > 0 && consecutiveBlanks <= config.MaxBlankLines {
				formatted = append(formatted, "")
			} else if config.MaxBlankLines == 0 {
				// Preserve exactly one blank line (original behavior)
				if consecutiveBlanks == 1 {
					formatted = append(formatted, "")
				}
			}
			i++
			continue
		}

		consecutiveBlanks = 0 // Reset on non-blank line

		// Check if this is a pipe continuation (any content after pending unbalanced paren with |)
		if pendingPipe && !isComment(trimmed) {
			joinedLine := joinedPipeContinuation(formatted, trimmed)
			formatted[len(formatted)-1] = joinedLine
			// Check if the joined result also has an unclosed paren with pipe
			joinedContent := strings.TrimRight(joinedLine, " \t")
			if hasUnbalancedOpenParens(joinedContent) {
				pendingPipe = true // Stay in pending mode for further continuations
			} else {
				pendingPipe = false
			}
			i++
			continue
		}

		// Detect sub-rule continuation: a non-comment, non-declaration line
		// that follows a declaration ending with ":"
		if prevWasDeclaration && !isComment(trimmed) && trimmed != "" {
			// Check if this is itself a new declaration (starts with ROOT/COORDINATE/ENSURE/BUILD/etc.)
			isNewDecl := isNewDeclarationLine(trimmed)
			if !isNewDecl {
				// This is a sub-rule continuation — indent it under the parent declaration
				formatted = append(formatted, strings.Repeat(" ", config.IndentWidth)+trimmed)
				if countUnclosedBracketsInEntries(formatted) > 0 {
					hadUnclosedBracketDepth = true
				}
				prevWasDeclaration = false
				i++
				continue
			}
		}

		// Check if this line ends with pipe and has unbalanced open parens (for next iteration)
		if trimmed != "" && !isComment(trimmed) {
			contentAfterPipe := strings.TrimRight(trimmed, "|& \t")
			pendingPipe = hasUnbalancedOpenParens(contentAfterPipe)

			// Update declaration tracking for sub-rule continuation detection
			endsDeclMarker := strings.HasSuffix(trimmed, ":") || strings.HasSuffix(trimmed, ",")
			hasUnmatchedBrackets := hasUnmatchedBracket(trimmed) && !isNewDeclarationLine(trimmed)

			prevWasDeclaration = endsDeclMarker || hasUnmatchedBrackets

			// Also check accumulated unclosed brackets across ALL formatted entries
			if !prevWasDeclaration {
				prevWasDeclaration = countUnclosedBracketsInEntries(formatted) > 0 || hadUnclosedBracketDepth
			}
		} else {
			pendingPipe = false
		}

		// Check if this is part of a consecutive comment group that needs alignment
		if isConsecutiveCommentGroup(lines, i) && !isBlockOpener(trimWhitespace(line)) && !isBlockCloser(trimWhitespace(line)) {
			groupEnd := findCommentGroupEnd(lines, i)
			commentGroup := lines[i:groupEnd]

			formatted = append(formatted, formatConsecutiveComments(commentGroup))
			i = groupEnd // Skip past the entire comment group (don't increment again)
		} else {
			formatted = append(formatted, formatLine(line, config, &nestingDepth))
			i++ // Move to next line after processing
		}
		// Track whether we've ever had unmatched bracket depth across all entries
		entryDepth := countUnclosedBracketsInEntries(formatted)
		if entryDepth > 0 {
			hadUnclosedBracketDepth = true
		} else if hasUnmatchedBracket(trimmed) && prevWasDeclaration {
			// Don't reset hadUnclosedBracketDepth for a bracket-group continuation.
		} else if hadUnclosedBracketDepth {
			hadUnclosedBracketDepth = false
		}
	}

	result := strings.Join(formatted, "\n")

	// Add trailing newline if not present
	if !strings.HasSuffix(result, "\n") {
		result += "\n"
	}

	return result, nil
}

// formatConsecutiveComments aligns consecutive comment lines to a common baseline.
func formatConsecutiveComments(lines []string) string {
	var aligned []string
	minIndent := -1

	// Find minimum indentation across all non-empty lines in the group
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		indent := countLeadingWhitespace(line)
		if minIndent == -1 || indent < minIndent {
			minIndent = indent
		}
	}

	// Apply consistent indentation by subtracting minIndent from each line
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			aligned = append(aligned, "") // Preserve blank lines in comment groups
			continue
		}
		indent := countLeadingWhitespace(line)
		relativeIndent := indent - minIndent
		padded := strings.Repeat(" ", relativeIndent) + trimWhitespace(line)
		aligned = append(aligned, padded)
	}

	return strings.Join(aligned, "\n")
}

// isConsecutiveCommentGroup checks if the current line starts a group of consecutive comments.
func isConsecutiveCommentGroup(lines []string, startIdx int) bool {
	if startIdx >= len(lines) {
		return false
	}

	current := strings.TrimSpace(lines[startIdx])
	if !isComment(current) {
		return false
	}

	// If this is the start of a multi-line block comment (/* or (* without closing */))
	// we need to include everything until the closing marker
	if isOpeningBlockComment(current) && !isClosingBlockComment(current) {
		// Find where the block comment ends
		endIdx := findBlockCommentEnd(lines, startIdx)
		if endIdx > startIdx+1 {
			return true // Multi-line block comment found
		}
		return false
	}

	// Check if next non-blank line is also a comment (single-line comments)
	for i := startIdx + 1; i < len(lines); i++ {
		next := strings.TrimSpace(lines[i])
		if next == "" {
			continue // Skip blank lines when checking for consecutive comments
		}
		return isComment(next) || isOpeningBlockComment(next)
	}

	return false
}

// findCommentGroupEnd finds the end index of a consecutive comment group.
func findCommentGroupEnd(lines []string, startIdx int) int {
	end := startIdx + 1

	// If this starts a multi-line block comment, skip to its closing marker
	if isOpeningBlockComment(strings.TrimSpace(lines[startIdx])) && !isClosingBlockComment(strings.TrimSpace(lines[startIdx])) {
		return findBlockCommentEnd(lines, startIdx)
	}

	for ; end < len(lines); end++ {
		trimmed := strings.TrimSpace(lines[end])
		if trimmed == "" || !isComment(trimmed) {
			break
		}
	}
	return end
}

// countLeadingWhitespace returns the number of leading whitespace characters.
func countLeadingWhitespace(line string) int {
	count := 0
	for _, ch := range line {
		if ch == ' ' || ch == '\t' {
			count++
		} else {
			break
		}
	}
	return count
}

// trimWhitespace removes leading and trailing whitespace from a string.
func trimWhitespace(s string) string {
	return strings.TrimSpace(s)
}

// isNewDeclarationLine checks if the line starts a new declaration (ROOT, COORDINATE, ENSURE, BUILD, SCHEMA, etc.)
func isNewDeclarationLine(line string) bool {
	upper := strings.ToUpper(strings.TrimSpace(line))
	declKeywords := []string{"ROOT", "COORDINATE", "ENSURE", "BUILD", "SCHEMA", "SHARE"}
	for _, kw := range declKeywords {
		if strings.HasPrefix(upper, kw+" ") || strings.HasPrefix(upper, kw+"\t") || upper == kw {
			return true
		}
	}
	return false
}

// formatLine applies formatting rules to a single line (non-comment group).
func formatLine(line string, config *Config, nestingDepth *int) string {
	trimmed := strings.TrimSpace(line)

	// Handle comments - preserve existing style exactly as-is
	if isComment(trimmed) {
		return trimTrailingWhitespace(trimmed)
	}

	// Detect block-closing keywords first (decrease depth BEFORE processing)
	if isBlockCloser(trimmed) {
		if *nestingDepth > 0 {
			*nestingDepth--
		}
	}

	// Apply consistent indentation based on nesting depth only for non-top-level code
	var indented string
	if *nestingDepth > 0 {
		indented = strings.Repeat(" ", *nestingDepth*config.IndentWidth) + trimmed
	} else {
		indented = trimmed
	}

	// Normalize tabs to spaces in non-comment lines
	indented = normalizeTabs(indented)

	// Detect block-opening keywords AFTER processing (increase depth for subsequent lines)
	if isBlockOpener(trimmed) && *nestingDepth >= 0 {
		*nestingDepth++
	}

	return indented
}

// hasUnmatchedBracket checks if a line ends with ] or ) that doesn't have a matching opening bracket/paren on the same line.
func hasUnmatchedBracket(line string) bool {
	trimmed := strings.TrimSpace(line)
	if len(trimmed) == 0 {
		return false
	}

	lastChar := trimmed[len(trimmed)-1]
	if lastChar != ']' && lastChar != ')' {
		return false
	}

	// Count brackets/parens in the entire line (not just trailing)
	openCount := strings.Count(trimmed, "(") + strings.Count(trimmed, "[")
	closeCount := strings.Count(trimmed, ")") + strings.Count(trimmed, "]")

	if openCount == 0 {
		return false
	}

	// If there are more opens than closes, the last bracket is part of an unclosed group
	return closeCount < openCount
}

// countUnclosedBracketsInEntries returns the accumulated bracket depth across all formatted entries.
// It sums ALL open brackets/parens and ALL close brackets/parens, then returns max(0, opens - closes).
func countUnclosedBracketsInEntries(formatted []string) int {
	totalOpen := 0
	totalClose := 0
	for _, entry := range formatted {
		totalOpen += strings.Count(entry, "[") + strings.Count(entry, "(")
		totalClose += strings.Count(entry, "]") + strings.Count(entry, ")")
	}
	if totalOpen > totalClose {
		return totalOpen - totalClose
	}
	return 0
}

// trimTrailingWhitespace removes trailing whitespace from a line while preserving content.
func trimTrailingWhitespace(line string) string {
	return strings.TrimRight(line, " \t")
}

// isBlockOpener checks if a line opens a new block (DO, BUILD).
func isBlockOpener(line string) bool {
	lower := strings.ToLower(strings.TrimSpace(line))
	// Match standalone DO or BUILD keywords
	if lower == "do" || lower == "build" {
		return true
	}
	// Match lines ending with DO (like "COORDINATE ... DO")
	if strings.HasSuffix(lower, " do") {
		return true
	}
	return false
}

// isBlockCloser checks if a line closes a block (OD;, FI;).
func isBlockCloser(line string) bool {
	lower := strings.ToLower(strings.TrimSpace(line))
	return lower == "od;" || lower == "fi;" || strings.HasSuffix(lower, ";") && (lower == "od" || lower == "fi")
}

// normalizeTabs converts tabs to spaces (config.IndentWidth per tab).
func normalizeTabs(line string) string {
	var sb strings.Builder
	for _, ch := range line {
		if ch == '\t' {
			sb.WriteString(strings.Repeat(" ", 4)) // MP convention: 1 tab = 4 spaces
		} else {
			sb.WriteRune(ch)
		}
	}
	return sb.String()
}

// isComment checks if a line is a comment (any style).
func isComment(line string) bool {
	return strings.HasPrefix(line, "//") ||
		strings.HasPrefix(line, "(*") ||
		strings.HasPrefix(line, "/*")
}

// isOpeningBlockComment returns true if the line opens a multi-line block comment.
func isOpeningBlockComment(trimmed string) bool {
	return (strings.HasPrefix(trimmed, "/*") && !strings.HasSuffix(trimmed, "*/")) ||
		(strings.HasPrefix(trimmed, "(*") && !strings.HasSuffix(trimmed, "*)"))
}

// isClosingBlockComment returns true if the line closes a multi-line block comment.
func isClosingBlockComment(trimmed string) bool {
	return strings.HasSuffix(trimmed, "*/") || strings.HasSuffix(trimmed, "*)")
}

// findBlockCommentEnd finds where a multi-line block comment ends (returns index of closing marker).
func findBlockCommentEnd(lines []string, startIdx int) int {
	trimmed := strings.TrimSpace(lines[startIdx])
	closingMarker := ""
	if strings.HasPrefix(trimmed, "/*") {
		closingMarker = "*/"
	} else if strings.HasPrefix(trimmed, "(*") {
		closingMarker = "*)"
	}

	for i := startIdx + 1; i < len(lines); i++ {
		lineTrimmed := strings.TrimSpace(lines[i])
		if strings.Contains(lineTrimmed, closingMarker) {
			return i + 1 // Return index AFTER the closing line (exclusive end for slicing)
		}
	}

	return startIdx + 1 // Fallback: treat as single-line if no closing found
}


// hasUnbalancedOpenParens checks if the line has more opening parens than closing ones,
// OR contains a pipe/ampersand that is still within an unclosed paren group. This indicates
// a multi-line parenthesized expression where continuations follow.
func hasUnbalancedOpenParens(line string) bool {
	// Remove trailing pipe/ampersand and trim
	cleaned := strings.TrimRight(strings.TrimSpace(line), "|& \t")

	openCount := strings.Count(cleaned, "(")
	closeCount := strings.Count(cleaned, ")")

	// Case 1: More opens than closes - definitely pending
	if openCount > closeCount {
		return true
	}

	// Case 2: Balanced parens (openCount == closeCount), check if any pipe/ampersand
	// appears in a group whose closing paren hasn't been reached yet. For balanced lines,
	// all groups are fully closed by end of line, so we only need to detect pipes that
	// appear AFTER the last closing paren (i.e., trailing branches outside groups).
	lastCloseIdx := strings.LastIndex(cleaned, ")")
	if lastCloseIdx >= 0 && lastCloseIdx < len(cleaned)-1 {
		afterLastClose := cleaned[lastCloseIdx+1:]
		if strings.Contains(afterLastClose, "|") || strings.Contains(afterLastClose, "&") {
			return true // Pipe after last close paren — continuation needed
		}
	}

	return false
}


// joinedPipeContinuation joins a pipe continuation line to the previous formatted line.
func joinedPipeContinuation(formatted []string, continuation string) string {
	if len(formatted) == 0 {
		return continuation
	}

	prevLine := formatted[len(formatted)-1]

	// Strip leading | or & from continuation and trim whitespace
	contContent := strings.TrimSpace(continuation)
	// Remove any leading pipe/ampersand (whether first char or after spaces)
	for len(contContent) > 0 && contContent[0] == '|' {
		contContent = contContent[1:]
	}

	// Strip only the last trailing pipe/ampersand (not all of them) to avoid eating intermediate pipes.
	// e.g., "( A |( B |" should become "( A |( B", not "( A |( ".
	cleanedPrev := strings.TrimRight(prevLine, " \t")
	if len(cleanedPrev) > 0 {
		last := cleanedPrev[len(cleanedPrev)-1]
		if last == '|' || last == '&' {
			cleanedPrev = cleanedPrev[:len(cleanedPrev)-1]
		}
	}
	return cleanedPrev + " |" + contContent
}
