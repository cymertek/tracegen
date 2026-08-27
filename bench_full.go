// Full benchmark comparing sequential vs parallel processing with memory measurement
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"github.com/cymertek/tracegen/internal/generator"
	"github.com/cymertek/tracegen/internal/parser"
	"github.com/cymertek/tracegen/internal/store"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: bench_full <mp_file> [scope]")
		os.Exit(1)
	}

	mpFile := os.Args[1]
	scope := 1
	if len(os.Args) > 2 {
		fmt.Sscanf(os.Args[2], "%d", &scope)
	}

	input, err := os.ReadFile(mpFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	tokens, err := parser.NewLexer(string(input)).Tokenize()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error tokenizing %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	schemaNode, err := parser.NewParser(tokens).Parse()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing %s: %v\n", mpFile, err)
		os.Exit(1)
	}

	gen := generator.NewCPUGenerator(0)

	dbStore, err := store.NewSQLiteStore(".")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating SQLite store: %v\n", err)
		os.Exit(1)
	}
	defer dbStore.Close()

	dbStore.ClearAll()

	// Measure parallel execution time and memory
	runtime.GC()
	var memBefore runtime.MemStats
	runtime.ReadMemStats(&memBefore)

	start := time.Now()
	err = gen.GenerateTracesToSQLite(schemaNode, scope, dbStore)
	duration := time.Since(start).Seconds()

	dbStore.Flush()
	count, _ := dbStore.QueryCount()

	var memAfter runtime.MemStats
	runtime.ReadMemStats(&memAfter)

	memDelta := int64(memAfter.TotalAlloc - memBefore.TotalAlloc)
	dbStore.Close()

	fmt.Printf("File: %s\n", filepath.Base(mpFile))
	fmt.Printf("Scope: %d\n", scope)
	fmt.Printf("Traces generated: %d\n", count)
	fmt.Printf("Execution time: %.4fs\n", duration)
	fmt.Printf("Memory allocated: %.2f MB\n", float64(memDelta)/(1024*1024))

	// Show dependency analysis
	groups := generator.FindIndependentGroups(schemaNode)
	if len(groups) > 1 {
		fmt.Printf("\nParallel processing detected: %d independent groups\n", len(groups))
		for i, g := range groups {
			fmt.Printf("  Group %d: coordinates [%v]\n", i+1, g)
		}
	} else {
		fmt.Println("\nSequential processing (single group)")
	}

	// Show GC stats for memory pressure analysis
	var gcStats runtime.MemStats
	runtime.ReadMemStats(&gcStats)
	fmt.Printf("\nGC Stats:\n")
	fmt.Printf("  Alloc: %.2f MB\n", float64(gcStats.Alloc)/(1024*1024))
	fmt.Printf("  TotalAlloc: %.2f MB\n", float64(gcStats.TotalAlloc)/(1024*1024))
	fmt.Printf("  Sys: %.2f MB\n", float64(gcStats.Sys)/(1024*1024))
	fmt.Printf("  NumGC: %d\n", gcStats.NumGC)
}