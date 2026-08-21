package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/cymertek/tracegen/internal/generator"
	"github.com/cymertek/tracegen/internal/parser"
)

func main() {
	input, err := os.ReadFile("/workdir/trace-generator/Firebird_Pre_loaded_examples/Example02_Data_flow.mp")
	if err != nil { fmt.Println(err); return }

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil { fmt.Println(err); return }

	schemaNode, err := parser.NewParser(tokens).Parse()
	if err != nil { fmt.Println(err); return }

	gen := generator.NewCPUGenerator(0)
	
	for _, scope := range []int{1, 2} {
		fmt.Printf("\n=== Example02 Data_flow scope=%d ===\n", scope)
		traces, err := gen.GenerateTraces(schemaNode, scope)
		if err != nil { fmt.Println(err); continue }
		
		fmt.Printf("Total traces: %d\n", len(traces))
		for i, t := range traces {
			eventNames := make([]string, len(t.Events))
			for j, e := range t.Events {
				eventNames[j] = fmt.Sprintf("%s(P%d)", e.Name, e.Position)
			}
			fmt.Printf("  [%d] Prob=%.4f Events(%d): %s\n", i, t.Probability, len(t.Events), strings.Join(eventNames, ", "))
		}
	}

	// Also test Example01 for regression check
	input2, err := os.ReadFile("/workdir/trace-generator/Firebird_Pre_loaded_examples/Example01_simple_message_flow.mp")
	if err != nil { fmt.Println("\nExample01 read error:", err); return }

	tokens2, err := parser.NewLexer(string(input2)).Tokenize()
	if err != nil { fmt.Println("Example01 tokenize error:", err); return }

	schemaNode2, err := parser.NewParser(tokens2).Parse()
	if err != nil { fmt.Println("Example01 parse error:", err); return }

	for _, scope := range []int{1, 2} {
		fmt.Printf("\n=== Example01 scope=%d ===\n", scope)
		traces, err := gen.GenerateTraces(schemaNode2, scope)
		if err != nil { fmt.Println(err); continue }
		
		fmt.Printf("Total traces: %d\n", len(traces))
		for i, t := range traces {
			eventNames := make([]string, len(t.Events))
			for j, e := range t.Events {
				eventNames[j] = e.Name
			}
			fmt.Printf("  [%d] Prob=%.4f Events(%d): %s\n", i, t.Probability, len(t.Events), strings.Join(eventNames, ", "))
		}
	}
}
