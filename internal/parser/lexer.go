// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package parser implements a Go-based parser for the MP behavioral event grammar language.
package parser

import (
	"os"
	"fmt"
	"strings"
)

// TokenType represents the type of a lexical token.
type TokenType int

const (
	TOKEN_EOF                  TokenType = iota
	TOKEN_WS                             // whitespace
	TOKEN_DIGIT                          // [0-9]
	TOKEN_INTEGER_CONSTANT               // -?[0-9]{1,18}
	TOKEN_FLOAT_CONSTANT                 // float with decimal point
	TOKEN_NUMBER_CONSTANT                // INTEGER or FLOAT
	TOKEN_STRICT_PROBABILITY             // .digits{1,6}
	TOKEN_PROBABILITY_CONSTANT           // STRICT or "0.strict" or "1."
	TOKEN_LETTER                         // [a-zA-Z]
	TOKEN_CNAME                          // identifier: _*(letter)(_|letter|digit)*
	TOKEN_STRING_CONSTANT                // double-quoted string
	TOKEN_VARIABLE                       // $CNAME
	TOKEN_NODE_VARIABLE                  // Node$CNAME
	TOKEN_NUMERIC_VARIABLE               // Num$CNAME
	TOKEN_COMMENT                        // (* ... *)

	// Keywords
	TOKEN_SCHEMA
	TOKEN_ROOT
	TOKEN_COORDINATE
	TOKEN_DO
	TOKEN_OD
	TOKEN_IF
	TOKEN_THEN
	TOKEN_ELSE
	TOKEN_FI
	TOKEN_FOR
	TOKEN_STEP
	TOKEN_SHARE
	TOKEN_ALL
	TOKEN_FROM
	TOKEN_ADD
	TOKEN_ENSURE
	TOKEN_CHECK
	TOKEN_ONFAIL
	TOKEN_SAY
	TOKEN_SET
	TOKEN_AT
	TOKEN_LEAST
	TOKEN_BUILD
	TOKEN_ATTRIBUTES
	TOKEN_NUMBER
	TOKEN_INTERVAL
	TOKEN_BOOLEAN
	TOKEN_TO // TO keyword in FOR loops
	TOKEN_REPORT
	TOKEN_GRAPH
	TOKEN_TABLE
	TOKEN_BAR
	TOKEN_CHART
	TITLE
	TABS
	X_AXIS
	ROTATE
	WITHIN
	FILL_EMPTY_NEST
	LOOP_OVER_GRAPH
	DO
	OD
	SHIFT_LEFT
	DISJ
	APPLY

	// Operators and punctuation
	TOKEN_LPAREN         // (
	TOKEN_RPAREN         // )
	TOKEN_LBRACE         // {
	TOKEN_RBRACE         // }
	TOKEN_LBRACKET       // [
	TOKEN_RBRACKET       // ]
	TOKEN_SEMICOLON      // ;
	TOKEN_COMMA          // ,
	TOKEN_COLON          // :
	TOKEN_DOT            // .
	TOKEN_ARROW          // ->
	TOKEN_BIDI_ARROW     // <-->
	TOKEN_IMPLY          // -->
	TOKEN_TILDE          // ~
	TOKEN_CARET          // ^
	TOKEN_PLUS           // +
	TOKEN_STAR           // *
	TOKEN_ITERATION_END  // *) - end of iteration scope
	TOKEN_QUESTION       // ?
	TOKEN_EQUALS         // ==
	TOKEN_NOT_EQUAL      // !=
	TOKEN_LESS           // <
	TOKEN_LESS_EQ        // <=
	TOKEN_GREATER        // >
	TOKEN_GREATER_EQ     // >=
	TOKEN_INTERVAL_START // < interval expression delimiter (bounded iterations)
	TOKEN_INTERVAL_END   // > interval expression delimiter (bounded iterations)
	TOKEN_ASSIGN         // :=
	TOKEN_ADD_ASSIGN     // +=
	TOKEN_SUB_ASSIGN     // -=
	TOKEN_MUL_ASSIGN     // *=
	TOKEN_DIV_ASSIGN     // /=
	TOKEN_DIVIDE         // /
	TOKEN_MIN_ASSIGN     // MIN=
	TOKEN_MAX_ASSIGN     // MAX=
	TOKEN_MINUS          // - (standalone minus)
	TOKEN_BANG           // ! (standalone bang)

	// Special tokens
	TOKEN_NOT             // NOT
	TOKEN_AND             // AND
	TOKEN_OR              // OR
	TOKEN_TRUE            // TRUE
	TOKEN_FALSE           // FALSE
	TOKEN_PRECEDES        // PRECEDES (used as relation name)
	TOKEN_IN              // IN (used as relation name)
	TOKEN_MAP             // MAP keyword
	TOKEN_THIS            // THIS keyword
	TOKEN_HASH            // # count operator
	TOKEN_ITERATION_START // (* - start of iteration pattern
)

// Token represents a single lexical token.
type Token struct {
	Type   TokenType
	Value  string
	Line   int
	Column int
}

// Lexer tokenizes .mp input into a stream of tokens.
type Lexer struct {
	input  string
	pos    int
	line   int
	column int
	tokens []Token
}

// NewLexer creates a new Lexer for the given input.
func NewLexer(input string) *Lexer {
	// Strip UTF-8 BOM if present (EF BB BF)
	input = strings.TrimPrefix(input, "\xEF\xBB\xBF")
	return &Lexer{
		input:  input,
		pos:    0,
		line:   1,
		column: 1,
		tokens: make([]Token, 0),
	}
}

// Tokenize processes the entire input and returns all tokens.
func (l *Lexer) Tokenize() ([]Token, error) {
	for l.pos < len(l.input) {
		token, err := l.nextToken()
		if err != nil {
			return nil, err
		}
		// Keep iteration start tokens, skip whitespace and comments
		if token.Type != TOKEN_WS && token.Type != TOKEN_COMMENT {
			l.tokens = append(l.tokens, token)
		}
	}
	l.tokens = append(l.tokens, Token{Type: TOKEN_EOF, Value: "", Line: l.line, Column: l.column})
	return l.tokens, nil
}

func (l *Lexer) nextToken() (Token, error) {

	ch := l.currentChar()

	switch {
	case ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r':
		return l.skipWhitespace(), nil
	case isLetter(ch):
		return l.scanIdentifier()
	case isDigit(ch):
		return l.scanNumber()
	case ch == '"':
		return l.scanString()
	case ch == '$':
		l.advance()
		if l.pos < len(l.input) && (isLetter(l.currentChar()) || l.currentChar() == '_') {
			name := l.scanIdentifierBody()
			return Token{Type: TOKEN_VARIABLE, Value: "$" + name, Line: l.line, Column: l.column}, nil
		}
		return Token{Type: TOKEN_VARIABLE, Value: "$", Line: l.line, Column: l.column}, nil
	case ch == 'N' && l.peek(1) == 'o' && l.peek(2) == 'd' && l.peek(3) == 'e':
		l.advanceN(4)
		if l.pos < len(l.input) && l.currentChar() == '$' {
			l.advance()
			name := l.scanIdentifierBody()
			return Token{Type: TOKEN_NODE_VARIABLE, Value: "Node$" + name, Line: l.line, Column: l.column}, nil
		}
		return Token{}, fmt.Errorf("unexpected 'Node' without '$' at line %d, column %d", l.line, l.column)
	case ch == 'N' && l.peek(1) == 'u' && l.peek(2) == 'm':
		l.advanceN(3)
		if l.pos < len(l.input) && l.currentChar() == '$' {
			l.advance()
			name := l.scanIdentifierBody()
			return Token{Type: TOKEN_NUMERIC_VARIABLE, Value: "Num$" + name, Line: l.line, Column: l.column}, nil
		}
		return Token{}, fmt.Errorf("unexpected 'Num' without '$' at line %d, column %d", l.line, l.column)
	case ch == '(':
		if l.peek(1) == '*' {
			return l.skipMPComment(), nil
		}
		l.advance()
		return Token{Type: TOKEN_LPAREN, Value: "(", Line: l.line, Column: l.column}, nil
	case ch == ')':
		l.advance()
		return Token{Type: TOKEN_RPAREN, Value: ")", Line: l.line, Column: l.column}, nil
	case ch == '{':
		l.advance()
		return Token{Type: TOKEN_LBRACE, Value: "{", Line: l.line, Column: l.column}, nil
	case ch == '}':
		l.advance()
		return Token{Type: TOKEN_RBRACE, Value: "}", Line: l.line, Column: l.column}, nil
	case ch == '[':
		l.advance()
		return Token{Type: TOKEN_LBRACKET, Value: "[", Line: l.line, Column: l.column}, nil
	case ch == ']':
		l.advance()
		return Token{Type: TOKEN_RBRACKET, Value: "]", Line: l.line, Column: l.column}, nil
	case ch == ';':
		l.advance()
		return Token{Type: TOKEN_SEMICOLON, Value: ";", Line: l.line, Column: l.column}, nil
	case ch == ',':
		l.advance()
		return Token{Type: TOKEN_COMMA, Value: ",", Line: l.line, Column: l.column}, nil
	case ch == ':':
		if l.peek(1) == '=' {
			l.advanceN(2)
			return Token{Type: TOKEN_ASSIGN, Value: ":=", Line: l.line, Column: l.column}, nil
		}
		if l.peek(1) == '+' {
			l.advanceN(2)
			return Token{Type: TOKEN_ADD_ASSIGN, Value: "+=", Line: l.line, Column: l.column}, nil
		}
		if l.peek(1) == '-' {
			l.advanceN(2)
			return Token{Type: TOKEN_SUB_ASSIGN, Value: "-=", Line: l.line, Column: l.column}, nil
		}
		if l.peek(1) == '*' {
			l.advanceN(2)
			return Token{Type: TOKEN_MUL_ASSIGN, Value: "*=", Line: l.line, Column: l.column}, nil
		}
		if l.peek(1) == '/' {
			l.advanceN(2)
			return Token{Type: TOKEN_DIV_ASSIGN, Value: "/=", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_COLON, Value: ":", Line: l.line, Column: l.column}, nil
	case ch == '.':
		if isDigit(l.peek(0)) {
			return l.scanProbability()
		}
		l.advance()
		return Token{Type: TOKEN_DOT, Value: ".", Line: l.line, Column: l.column}, nil
	case ch == '-':
		if l.peek(1) == '>' {
			if l.peek(2) == '>' {
				l.advanceN(3)
				return Token{Type: TOKEN_BIDI_ARROW, Value: "<-->", Line: l.line, Column: l.column}, nil
			}
			l.advanceN(2)
			return Token{Type: TOKEN_IMPLY, Value: "-->", Line: l.line, Column: l.column}, nil
		}
		if isDigit(l.peek(0)) {
			return l.scanNumber()
		}
		l.advance()
		return Token{Type: TOKEN_MINUS, Value: "-", Line: l.line, Column: l.column}, nil
	case ch == '=':
		if l.peek(1) == '=' {
			l.advanceN(2)
			return Token{Type: TOKEN_EQUALS, Value: "==", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_ASSIGN, Value: "=", Line: l.line, Column: l.column}, nil
	case ch == '!':
		if l.peek(1) == '=' {
			l.advanceN(2)
			return Token{Type: TOKEN_NOT_EQUAL, Value: "!=", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_BANG, Value: "!", Line: l.line, Column: l.column}, nil
	case ch == '<':
		if l.peek(1) == '<' {
			l.advanceN(2)
			return l.scanProbabilityValue()
		}
		// Check if this is an interval expression delimiter for bounded iterations
		// Pattern: <digit|letter|variable> .. <expression>
		l.advance() // skip the '<'
		if l.pos < len(l.input) {
			nextChar := l.currentChar()
			// If followed by digit, letter, or variable start, it's an interval delimiter
			if isDigit(nextChar) || isLetter(nextChar) || nextChar == '$' {
				return Token{Type: TOKEN_INTERVAL_START, Value: "<", Line: l.line, Column: l.column}, nil
			}
		}
		// Otherwise treat as comparison operator (less-than)
		l.advance() // advance past '<'
		os.Stderr.Sync()
		return Token{Type: TOKEN_LESS, Value: "<", Line: l.line, Column: l.column}, nil
	case ch == '/':
		if l.peek(1) == '*' {
			return l.skipCStyleComment(), nil
		}
		l.advance()
		return Token{Type: TOKEN_DIVIDE, Value: "/", Line: l.line, Column: l.column}, nil
	case ch == '>':
		if l.peek(1) == '>' {
			l.advanceN(2)
			return Token{Type: TOKEN_GREATER_EQ, Value: ">>", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_GREATER, Value: ">", Line: l.line, Column: l.column}, nil
	case ch == '~':
		l.advance()
		return Token{Type: TOKEN_TILDE, Value: "~", Line: l.line, Column: l.column}, nil
	case ch == '^':
		l.advance()
		return Token{Type: TOKEN_CARET, Value: "^", Line: l.line, Column: l.column}, nil
	case ch == '|':
		l.advance()
		return Token{Type: TOKEN_BAR, Value: "|", Line: l.line, Column: l.column}, nil
	case ch == '*':
		if l.peek(1) == ')' {
			l.advanceN(2) // skip *)
			return Token{Type: TOKEN_ITERATION_END, Value: "*)", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_STAR, Value: "*", Line: l.line, Column: l.column}, nil
	case ch == '#':
		l.advance()
		return Token{Type: TOKEN_HASH, Value: "#", Line: l.line, Column: l.column}, nil
	case ch == '+':
		if l.peek(1) == '=' {
			l.advanceN(2)
			return Token{Type: TOKEN_ADD_ASSIGN, Value: "+=", Line: l.line, Column: l.column}, nil
		}
		l.advance()
		return Token{Type: TOKEN_PLUS, Value: "+", Line: l.line, Column: l.column}, nil
	default:
		return Token{}, fmt.Errorf("unexpected character '%c' at line %d, column %d", ch, l.line, l.column)
	}
}

func (l *Lexer) currentChar() byte {
	if l.pos >= len(l.input) {
		return 0
	}
	return l.input[l.pos]
}

func (l *Lexer) peek(offset int) byte {
	pos := l.pos + offset
	if pos >= len(l.input) {
		return 0
	}
	return l.input[pos]
}

func (l *Lexer) advance() {
	if l.pos < len(l.input) {
		if l.input[l.pos] == '\n' {
			l.line++
			l.column = 1
		} else {
			l.column++
		}
		l.pos++
	}
}

func (l *Lexer) advanceN(n int) {
	for i := 0; i < n; i++ {
		l.advance()
	}
}

func (l *Lexer) skipWhitespace() Token {
	startLine := l.line
	startCol := l.column
	for l.pos < len(l.input) && (l.currentChar() == ' ' || l.currentChar() == '\t' || l.currentChar() == '\n' || l.currentChar() == '\r') {
		l.advance()
	}
	return Token{Type: TOKEN_WS, Value: "", Line: startLine, Column: startCol}
}

func (l *Lexer) skipMPComment() Token {
	startLine := l.line
	startCol := l.column

	// Save position after opening (* so we can emit it and continue parsing content
	l.advanceN(2) // skip (*

	isIteration := false
	skippedWhitespace := false
	if l.pos < len(l.input) {
		ch := l.currentChar()
		if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_' {
			isIteration = true
		} else if ch == '(' {
			isIteration = true // (* ( ... *) is iteration scope with nested group
		} else if ch == ' ' || ch == '\t' || ch == '\n' {
			savedPos2 := l.pos
			for l.pos < len(l.input) && (l.currentChar() == ' ' || l.currentChar() == '\t' || l.currentChar() == '\n') {
				l.advance()
			}
			if l.pos < len(l.input) {
				next := l.currentChar()
				if (next >= 'a' && next <= 'z') || (next >= 'A' && next <= 'Z') || next == '_' || next == '(' {
					isIteration = true
				} else if next != '*' || l.peek(1) != ')' {
					skippedWhitespace = true // consumed whitespace past *) — it's a comment
				}
			}
			l.pos = savedPos2 // restore to after whitespace but before identifier
		}
	}

	if isIteration && !skippedWhitespace {
		// This is an iteration scope — emit ITERATION_START and leave position after (*
		return Token{Type: TOKEN_ITERATION_START, Value: "", Line: startLine, Column: startCol}
	}

	// Otherwise it's a true comment - consume until closing *)
	for l.pos < len(l.input)-1 && (l.currentChar() != '*' || l.peek(1) != ')') {
		l.advance()
	}
	if l.pos < len(l.input)-1 {
		l.advanceN(2) // skip *)
	}

	return Token{Type: TOKEN_COMMENT, Value: "", Line: startLine, Column: startCol}
}

func (l *Lexer) skipCStyleComment() Token {
	startLine := l.line
	startCol := l.column
	l.advanceN(2) // skip /*

	// Consume until closing */
	for l.pos < len(l.input)-1 && (l.currentChar() != '*' || l.peek(1) != '/') {
		l.advance()
	}
	if l.pos < len(l.input)-1 {
		l.advanceN(2) // skip */
	}

	return Token{Type: TOKEN_COMMENT, Value: "", Line: startLine, Column: startCol}
}

func (l *Lexer) scanIdentifier() (Token, error) {
	start := l.pos
	startLine := l.line
	startCol := l.column
	l.advance() // skip first letter

	for l.pos < len(l.input) && (isLetter(l.currentChar()) || isDigit(l.currentChar()) || l.currentChar() == '_') {
		l.advance()
	}

	value := l.input[start:l.pos]

	// Check for keywords
	tokenType := l.lookupKeyword(value)
	if tokenType != 0 {
		return Token{Type: tokenType, Value: value, Line: startLine, Column: startCol}, nil
	}

	return Token{Type: TOKEN_CNAME, Value: value, Line: startLine, Column: startCol}, nil
}

func (l *Lexer) scanIdentifierBody() string {
	start := l.pos
	for l.pos < len(l.input) && (isLetter(l.currentChar()) || isDigit(l.currentChar()) || l.currentChar() == '_') {
		l.advance()
	}
	return l.input[start:l.pos]
}

func (l *Lexer) scanNumber() (Token, error) {
	start := l.pos
	startLine := l.line
	startCol := l.column

	if l.currentChar() == '-' {
		l.advance()
	}

	isFloat := false
	for l.pos < len(l.input) && isDigit(l.currentChar()) {
		l.advance()
	}

	if l.pos < len(l.input) && l.currentChar() == '.' {
		isFloat = true
		l.advance()
		for l.pos < len(l.input) && isDigit(l.currentChar()) {
			l.advance()
		}
	}

	value := l.input[start:l.pos]
	tokenType := TOKEN_INTEGER_CONSTANT
	if isFloat {
		tokenType = TOKEN_FLOAT_CONSTANT
	}

	return Token{Type: tokenType, Value: value, Line: startLine, Column: startCol}, nil
}

func (l *Lexer) scanString() (Token, error) {
	startLine := l.line
	startCol := l.column
	l.advance() // skip opening "

	var sb strings.Builder
	for l.pos < len(l.input) && l.currentChar() != '"' {
		if l.currentChar() == '\\' && l.peek(1) == '"' {
			sb.WriteByte('"')
			l.advanceN(2)
		} else {
			sb.WriteByte(l.currentChar())
			l.advance()
		}
	}

	if l.pos >= len(l.input) {
		return Token{}, fmt.Errorf("unterminated string at line %d, column %d", startLine, startCol)
	}

	l.advance() // skip closing "
	value := sb.String()

	return Token{Type: TOKEN_STRING_CONSTANT, Value: value, Line: startLine, Column: startCol}, nil
}

func (l *Lexer) scanProbability() (Token, error) {
	startLine := l.line
	startCol := l.column

	// Skip the dot
	l.advance()

	// Scan digits
	var sb strings.Builder
	for l.pos < len(l.input) && isDigit(l.currentChar()) {
		sb.WriteByte(l.currentChar())
		l.advance()
	}

	value := "." + sb.String()
	return Token{Type: TOKEN_STRICT_PROBABILITY, Value: value, Line: startLine, Column: startCol}, nil
}

func (l *Lexer) scanProbabilityValue() (Token, error) {
	startLine := l.line
	startCol := l.column

	// Note: advanceN(2) was already called in nextToken to skip opening <<

	var sb strings.Builder
	for l.pos < len(l.input) && l.currentChar() != '>' {
		sb.WriteByte(l.currentChar())
		l.advance()
	}

	if l.pos >= len(l.input) || l.currentChar() != '>' {
		return Token{}, fmt.Errorf("unterminated probability at line %d, column %d", startLine, startCol)
	}

	l.advance() // skip closing >
	if l.pos < len(l.input) && l.currentChar() == '>' {
		l.advance() // skip second closing >
	}

	value := sb.String()
	return Token{Type: TOKEN_PROBABILITY_CONSTANT, Value: value, Line: startLine, Column: startCol}, nil
}

func (l *Lexer) lookupKeyword(value string) TokenType {
	switch strings.ToUpper(value) {
	case "SCHEMA":
		return TOKEN_SCHEMA
	case "ROOT":
		return TOKEN_ROOT
	case "COORDINATE":
		return TOKEN_COORDINATE
	case "DO":
		return TOKEN_DO
	case "OD":
		return TOKEN_OD
	case "IF":
		return TOKEN_IF
	case "THEN":
		return TOKEN_THEN
	case "ELSE":
		return TOKEN_ELSE
	case "FI":
		return TOKEN_FI
	case "FOR":
		return TOKEN_FOR
	case "STEP":
		return TOKEN_STEP
	case "SHARE":
		return TOKEN_SHARE
	case "ALL":
		return TOKEN_ALL
	case "FROM":
		return TOKEN_FROM
	case "ADD":
		return TOKEN_ADD
	case "ENSURE":
		return TOKEN_ENSURE
	case "CHECK":
		return TOKEN_CHECK
	case "ONFAIL":
		return TOKEN_ONFAIL
	case "SAY":
		return TOKEN_SAY
	case "SET":
		return TOKEN_SET
	case "AT":
		return TOKEN_AT
	case "LEAST":
		return TOKEN_LEAST
	case "BUILD":
		return TOKEN_BUILD
	case "ATTRIBUTES":
		return TOKEN_ATTRIBUTES
	case "NUMBER":
		return TOKEN_NUMBER
	case "INTERVAL":
		return TOKEN_INTERVAL
	case "BOOLEAN":
		return TOKEN_BOOLEAN
	case "REPORT":
		return TOKEN_REPORT
	case "GRAPH":
		return TOKEN_GRAPH
	case "TABLE":
		return TOKEN_TABLE
	case "BAR":
		return TOKEN_BAR
	case "CHART":
		return TOKEN_CHART
	case "TITLE":
		return TITLE
	case "TABS":
		return TABS
	case "X_AXIS":
		return X_AXIS
	case "ROTATE":
		return ROTATE
	case "WITHIN":
		return WITHIN
	case "DISJ":
		return DISJ
	case "APPLY":
		return APPLY
	case "MAP":
		return TOKEN_MAP
	case "THIS":
		return TOKEN_THIS
	case "NOT":
		return TOKEN_NOT
	case "AND":
		return TOKEN_AND
	case "OR":
		return TOKEN_OR
	case "TRUE":
		return TOKEN_TRUE
	case "FALSE":
		return TOKEN_FALSE
	default:
		return 0
	}
}

func isLetter(ch byte) bool {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

func isDigit(ch byte) bool {
	return ch >= '0' && ch <= '9'
}
