// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.
package model

import (
	"fmt"

	"github.com/cymertek/tracegen/internal/parser"
)

// Unmarshal parses .mp text format into a Schema.
func Unmarshal(text string) (*Schema, error) {
	tokens, err := parser.NewLexer(text).Tokenize()
	if err != nil {
		return nil, fmt.Errorf("tokenizing: %w", err)
	}

	p := parser.NewParser(tokens)
	schemaNode, err := p.Parse()
	if err != nil {
		return nil, err
	}

	// Convert parser.SchemaNode to model.Schema
	schema := &Schema{
		Name:             schemaNode.Name,
		Rules:            make([]Rule, 0),
		Attributes:       convertAttributeDeclarations(schemaNode.Attributes),
		ViewDescriptions: make([]ViewDescription, 0),
	}

	for _, ruleNode := range schemaNode.Rules {
		rule := Rule{
			Name:        ruleNode.Name,
			PatternList: convertPatternList(ruleNode.PatternList),
			IsRoot:      ruleNode.IsRoot,
		}
		if ruleNode.BuildBlock != nil {
			rule.BuildBlock = &BuildBlock{
				Operations: convertCompositionOps(ruleNode.BuildBlock.Operations),
			}
		}
		schema.Rules = append(schema.Rules, rule)
	}

	return schema, nil
}

func convertPatternList(patterns parser.PatternListNode) PatternList {
	var result PatternList
	for _, p := range patterns {
		switch v := p.(type) {
		case *parser.AtomicEventNode:
			event := EventPattern{
				Name:        v.Name,
				Probability: convertProbability(v.Probability),
			}
			if v.Variable != nil {
				event.Variable = *v.Variable
			}
			result = append(result, event)
		case *parser.AltGroupNode:
			// For alternatives, just take the first alternative's events for now
			for _, alt := range v.Alternatives {
				subEvents := convertPatternList(alt.PatternList)
				result = append(result, subEvents...)
			}
		default:
			// Skip other pattern types (list, set, etc.) for now
		}
	}
	return result
}

// Helper to convert parser attribute declarations to model type.
func convertAttributeDeclarations(attrs []parser.AttributeDeclarationNode) []AttributeDeclaration {
	var result []AttributeDeclaration
	for _, a := range attrs {
		result = append(result, AttributeDeclaration{
			Name: a.Name,
			Type: a.Type,
		})
	}
	return result
}

// Helper to convert parser composition operations to model types.
func convertCompositionOps(ops []parser.CompositionOpNode) []CompositionOperation {
	var result []CompositionOperation
	for _, op := range ops {
		switch op.Type {
		case "ADD":
			result = append(result, AddRelation{
				RelDomain1: RelationDomain{}, // simplified - full conversion would need more context
			})
		case "ENSURE":
			if be, ok := op.Expression.(parser.BoolExprNode); ok {
				result = append(result, EnsureRequest{
					Condition: convertBoolExpr(be),
				})
			}
		default:
			// Skip unsupported operation types for now
		}
	}
	return result
}

// Helper to convert parser boolean expressions.
func convertBoolExpr(node parser.BoolExprNode) BoolExpr {
	switch v := node.(type) {
	case *parser.BoolLiteralNode:
		return BoolLiteral{Value: v.Value}
	case *parser.BoolAndNode:
		return BoolAnd{
			Left:  convertBoolExpr(v.Left),
			Right: convertBoolExpr(v.Right),
		}
	case *parser.BoolOrNode:
		return BoolOr{
			Left:  convertBoolExpr(v.Left),
			Right: convertBoolExpr(v.Right),
		}
	default:
		return BoolLiteral{Value: false} // fallback
	}
}

func convertProbability(prob *parser.ProbabilityNode) *float64 {
	if prob == nil {
		return nil
	}
	value := prob.Value
	return &value
}
