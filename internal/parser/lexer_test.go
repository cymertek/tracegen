// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package parser

import (
	"fmt"
	"testing"
)

func TestLexerBasicTokens(t *testing.T) {
	input := "SCHEMA MySchema;"
	tokens, err := NewLexer(input).Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	expectedTypes := []TokenType{TOKEN_SCHEMA, TOKEN_CNAME, TOKEN_SEMICOLON}
	for i, expected := range expectedTypes {
		if tokens[i].Type != expected {
			t.Errorf("token %d: expected type %v, got %v", i, expected, tokens[i].Type)
		}
	}

	if string(tokens[1].Value) != "MySchema" {
		t.Errorf("expected 'MySchema', got '%s'", tokens[1].Value)
	}
}

func TestLexerComments(t *testing.T) {
	input := `// This is a comment
SCHEMA Test;`
	tokens, err := NewLexer(input).Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	// Should skip comments and only return SCHEMA and Test tokens
	if len(tokens) < 2 {
		t.Errorf("expected at least 2 tokens, got %d", len(tokens))
	}
}

func TestLexerKeywords(t *testing.T) {
	input := "ROOT Sender: send; COORDINATE $x: FROM Sender DO ADD $x PRECEDES $y OD;"
	lexer := NewLexer(input)
	tokens, err := lexer.Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	keywordsFound := make(map[string]bool)
	for _, tok := range tokens {
		switch tok.Type {
		case TOKEN_ROOT, TOKEN_COORDINATE, TOKEN_DO, TOKEN_OD, TOKEN_FROM:
			keywordsFound[TokenTypeName(tok.Type)] = true
		}
	}

	expectedKeywords := []string{"'ROOT'", "'COORDINATE'", "'DO'", "'OD'", "'FROM'"}
	for _, kw := range expectedKeywords {
		if !keywordsFound[kw] {
			t.Errorf("expected keyword %s not found in tokens", kw)
		}
	}
}

func TestLexerStrings(t *testing.T) {
	input := `ROOT Sender: "send event";`
	tokens, err := NewLexer(input).Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	var foundString bool
	for _, tok := range tokens {
		if tok.Type == TOKEN_STRING_CONSTANT && string(tok.Value) == "send event" {
			foundString = true
		}
	}

	if !foundString {
		t.Error("expected to find string constant 'send event'")
	}
}

func TestLexerProbabilityAnnotation(t *testing.T) {
	input := `<<0.75>>`
	lexer := NewLexer(input)
	tokens, err := lexer.Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	var foundProbability bool
	for _, tok := range tokens {
		fmt.Printf("Token: Type=%v Value=%q\n", tok.Type, string(tok.Value))
		if tok.Type == TOKEN_PROBABILITY_CONSTANT || tok.Type == TOKEN_STRICT_PROBABILITY {
			foundProbability = true
		}
	}

	if !foundProbability {
		t.Error("expected to find probability annotation token")
	}
}

func TestLexerIterationScopes(t *testing.T) {
	input := `(send)`
	lexer := NewLexer(input)
	tokens, err := lexer.Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	var foundParen bool
	for _, tok := range tokens {
		if tok.Type == TOKEN_LPAREN {
			foundParen = true
		}
	}

	if !foundParen {
		t.Error("expected to find left parenthesis for iteration scope")
	}
}

func TestLexerEmptyInput(t *testing.T) {
	input := ""
	tokens, err := NewLexer(input).Tokenize()
	if err != nil {
		t.Fatalf("lexer failed on empty input: %v", err)
	}

	if len(tokens) == 0 {
		t.Error("expected at least EOF token")
	}
}

func TestLexerDebugProbability(t *testing.T) {
	input := `<<0.75>>`
	lexer := NewLexer(input)
	tokens, err := lexer.Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	for _, tok := range tokens {
		fmt.Printf("Token: Type=%v Value=%q\n", tok.Type, string(tok.Value))
	}
}

func TestLexerDebugIteration(t *testing.T) {
	input := `ROOT Sender: (* send *);`
	lexer := NewLexer(input)
	tokens, err := lexer.Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	for _, tok := range tokens {
		fmt.Printf("Token: Type=%v Value=%q\n", tok.Type, string(tok.Value))
	}
}

func TestLexerSpecialCharacters(t *testing.T) {
	input := `x == y`
	tokens, err := NewLexer(input).Tokenize()
	if err != nil {
		t.Fatalf("lexer failed: %v", err)
	}

	var foundEquals bool
	for _, tok := range tokens {
		if tok.Type == TOKEN_EQUALS || tok.Type == TOKEN_NOT_EQUAL {
			foundEquals = true
		}
	}

	if !foundEquals {
		t.Error("expected to find equality operator token")
	}
}