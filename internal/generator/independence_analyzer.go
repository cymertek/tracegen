// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"fmt"
	"strings"

	"github.com/cymertek/tracegen/internal/parser"
)

// CoordinateDependency represents a dependency relationship between coordinate blocks
type CoordinateDependency struct {
	CoordinateIdx int
	DependsOn     []int // indices of coordinates this depends on
	SharedEvents  map[string][]int // event names shared with other coordinates
}

// AnalyzeCoordinateDependencies identifies independent groups of coordinate blocks
func AnalyzeCoordinateDependencies(schema *parser.SchemaNode) []CoordinateDependency {
	deps := make([]CoordinateDependency, len(schema.Coordinates))

	for i := range deps {
		deps[i] = CoordinateDependency{
			CoordinateIdx: i,
			SharedEvents:  make(map[string][]int),
		}
	}

	// Build a map of all events to their coordinate indices
	eventToCoords := make(map[string][]int)
	for i, coord := range schema.Coordinates {
		for _, thread := range coord.Threads {
			if thread.EventName != "" {
				eventToCoords[thread.EventName] = append(eventToCoords[thread.EventName], i)
			}
		}

		// Note: Variables like $x, $y are local to each coordinate block
		// and don't create dependencies between coordinates that operate on different events
	}

	// Identify dependencies based on shared events (not variables)
	for event, coordIndices := range eventToCoords {
		if len(coordIndices) > 1 {
			// This event is shared between multiple coordinates - they're dependent
			for _, idx := range coordIndices[1:] {
				deps[idx].DependsOn = addUnique(deps[idx].DependsOn, coordIndices[0])
				deps[coordIndices[0]].SharedEvents[event] = append(
					deps[coordIndices[0]].SharedEvents[event], idx)
			}

			// Track which coordinates share this event (avoid duplicates)
			for _, idx := range coordIndices {
				if len(coordIndices) > 1 {
					deps[idx].SharedEvents[event] = append(
						deps[idx].SharedEvents[event], coordIndices...)
				}
			}
		}
	}

	return deps
}

// FindIndependentGroups returns groups of coordinates that can be processed independently
func FindIndependentGroups(schema *parser.SchemaNode) [][]int {
	deps := AnalyzeCoordinateDependencies(schema)

	if len(deps) == 0 {
		return nil
	}

	// Build adjacency list for dependency graph
	adjList := make(map[int][]int)
	for _, dep := range deps {
		for _, depIdx := range dep.DependsOn {
			adjList[depIdx] = append(adjList[depIdx], dep.CoordinateIdx)
		}
	}

	// Find connected components using BFS/DFS
	visited := make(map[int]bool)
	var groups [][]int

	for i := 0; i < len(deps); i++ {
		if !visited[i] {
			group := bfs(adjList, visited, i)
			groups = append(groups, group)
		}
	}

	return groups
}

// bfs performs breadth-first search to find connected components
func bfs(adjList map[int][]int, visited map[int]bool, start int) []int {
	queue := []int{start}
	visited[start] = true
	var component []int

	for len(queue) > 0 {
		node := queue[0]
		queue = queue[1:]
		component = append(component, node)

		for _, neighbor := range adjList[node] {
			if !visited[neighbor] {
				visited[neighbor] = true
				queue = append(queue, neighbor)
			}
		}
	}

	return component
}

// addUnique adds an element to a slice if not already present
func addUnique(slice []int, elem int) []int {
	for _, e := range slice {
		if e == elem {
			return slice
		}
	}
	return append(slice, elem)
}

// PrintDependencyAnalysis prints analysis of coordinate dependencies for debugging
func PrintDependencyAnalysis(schema *parser.SchemaNode) {
	deps := AnalyzeCoordinateDependencies(schema)
	groups := FindIndependentGroups(schema)

	fmt.Println("=== Coordinate Dependency Analysis ===")
	fmt.Printf("Total coordinates: %d\n", len(deps))
	fmt.Printf("Independent groups: %d\n", len(groups))

	for i, group := range groups {
		if len(group) > 1 {
			fmt.Printf("\nGroup %d (DEPENDENT): ", i+1)
			events := make([]string, 0)
			for _, idx := range group {
				events = append(events, fmt.Sprintf("Coord[%d]", idx))
				for event := range deps[idx].SharedEvents {
					events = append(events, fmt.Sprintf("  - %s", event))
				}
			}
			fmt.Println(strings.Join(events, ", "))
		} else if len(group) == 1 {
			idx := group[0]
			fmt.Printf("\nGroup %d (INDEPENDENT): Coord[%d]", i+1, idx)
			if len(deps[idx].SharedEvents) > 0 {
				fmt.Print(" (but shares events: ")
				for event := range deps[idx].SharedEvents {
					fmt.Printf("%s ", event)
				}
				fmt.Print(")")
			}
			fmt.Println()
		}
	}
}
