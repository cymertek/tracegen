// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package main

import (
    "fmt"
    "os"
    
    "github.com/cymertek/tracegen/internal/parser"
)

func main() {
    if len(os.Args) < 2 {
        fmt.Println("Usage: debug parse <file.mp>")
        os.Exit(1)
    }
    
    data, err := os.ReadFile(os.Args[1])
    if err != nil {
        fmt.Println("Error reading file:", err)
        return
    }
    
    lexer := parser.NewLexer(string(data))
    tokens, err := lexer.Tokenize()
    if err != nil {
        fmt.Println("Lexing error:", err)
        return
    }
    fmt.Printf("Tokens: %d\n", len(tokens))
    
    p := parser.NewParser(tokens)
    schema, err := p.Parse()
    if err != nil {
        fmt.Println("Parsing error:", err)
        return
    }
    fmt.Printf("Schema: %s\n", schema.Name)
    fmt.Printf("Rules: %d\n", len(schema.Rules))
    for i, r := range schema.Rules {
        fmt.Printf("  Rule[%d]: %s (root=%v)\n", i, r.Name, r.IsRoot)
        fmt.Printf("    Patterns: %d\n", len(r.PatternList))
        for j, pat := range r.PatternList {
            fmt.Printf("      Pattern[%d]: %T\n", j, pat)
        }
    }
}
