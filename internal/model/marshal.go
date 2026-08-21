// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.
package model

import (
	"fmt"
	"strings"
)

// Marshal converts a Schema to .mp text format.
func (s *Schema) Marshal() string {
	var b strings.Builder
	fmt.Fprintf(&b, "SCHEMA %s\n", s.Name)

	for _, rule := range s.Rules {
		b.WriteString(rule.Marshal())
	}

	if len(s.Attributes) > 0 {
		b.WriteString(marshalAttributes(s.Attributes))
	}

	for _, view := range s.ViewDescriptions {
		b.WriteString(view.Marshal())
	}

	return b.String()
}

// Marshal converts a Rule to .mp text format.
func (r *Rule) Marshal() string {
	var b strings.Builder

	if r.IsRoot {
		b.WriteString("ROOT ")
	}

	b.WriteString(r.Name)
	b.WriteString(": ")
	b.WriteString(r.PatternList.Marshal())

	if r.BuildBlock != nil {
		b.WriteString(r.BuildBlock.Marshal())
	}

	b.WriteString(";\n")
	return b.String()
}

// Marshal converts a BuildBlock to .mp text format.
func (b *BuildBlock) Marshal() string {
	var sb strings.Builder
	sb.WriteString("BUILD {\n")
	for _, op := range b.Operations {
		sb.WriteString(marshalCompositionOp(op, 1))
	}
	sb.WriteString("}\n")
	return sb.String()
}

// Marshal converts a ViewDescription to .mp text format.
func (v *ViewDescription) Marshal() string {
	var sb strings.Builder

	switch v.Type {
	case "REPORT":
		fmt.Fprintf(&sb, "REPORT %s", v.Name)
	case "GRAPH":
		fmt.Fprintf(&sb, "GRAPH %s", v.Name)
	case "TABLE":
		fmt.Fprintf(&sb, "TABLE %s", v.Name)
	case "BAR":
		fmt.Fprintf(&sb, "BAR CHART %s", v.Name)
	}

	sb.WriteString(" {\n")

	if v.Title != nil {
		fmt.Fprintf(&sb, "    TITLE \"%s\";\n", *v.Title)
	}

	if len(v.Tabs) > 0 {
		for _, tab := range v.Tabs {
			fmt.Fprintf(&sb, "    TABS %s;\n", strings.Join(tab, ", "))
		}
	}

	if v.XAxis != nil {
		fmt.Fprintf(&sb, "    X_AXIS %s;\n", *v.XAxis)
	}

	if v.Rotate {
		sb.WriteString("    ROTATE;\n")
	}

	for _, op := range v.Operations {
		sb.WriteString(marshalGraphOp(op, 1))
	}

	sb.WriteString("}\n")
	return sb.String()
}

// Marshal converts a PatternList to .mp text format.
func (p PatternList) Marshal() string {
	var parts []string
	for _, event := range p {
		parts = append(parts, marshalEventPattern(event))
	}
	return strings.Join(parts, " ")
}

// Marshal converts an EventPattern to .mp text format.
func marshalEventPattern(event EventPattern) string {
	var sb strings.Builder

	if event.Variable != "" {
		sb.WriteString("$" + event.Variable + ": ")
	} else if event.NodeVar != "" {
		sb.WriteString("Node$" + event.NodeVar + ": ")
	}

	sb.WriteString(event.Name)

	if event.Probability != nil {
		fmt.Fprintf(&sb, " <<%.6f>>", *event.Probability)
	}

	return sb.String()
}

// Marshal converts a CompositionOperation to .mp text format.
func marshalCompositionOp(op CompositionOperation, indent int) string {
	var sb strings.Builder
	prefix := strings.Repeat("    ", indent)

	switch v := op.(type) {
	case SharedComposition:
		sb.WriteString(prefix)
		var vars []string
		for _, varName := range v.Variables {
			vars = append(vars, "$"+varName)
		}
		if len(vars) > 0 {
			sb.WriteString(strings.Join(vars, ", "))
		} else {
			sb.WriteString("THIS")
		}
		sb.WriteString(" SHARE ALL ")
		sb.WriteString(strings.Join(v.Events, ", "))
		sb.WriteString("\n")

	case AsyncCoordinateOp:
		sb.WriteString(prefix + "COORDINATE <!>\n")
		sb.WriteString(marshalThreadSelection(v.Thread, indent+1))
		sb.WriteString(prefix + "    DO\n")
		for _, action := range v.DoBlock.Actions {
			sb.WriteString(marshalSimpleAction(action, indent+2))
		}
		sb.WriteString(prefix + "    OD;\n")

	case LockstepCoordinateOp:
		sb.WriteString(prefix + "COORDINATE\n")
		var threads []string
		for _, t := range v.Threads {
			threads = append(threads, marshalThreadSelection(t, indent+1))
		}
		sb.WriteString(strings.Join(threads, ",\n"))
		sb.WriteString("\n" + prefix + "    DO\n")
		for _, action := range v.DoBlock.Actions {
			sb.WriteString(marshalSimpleAction(action, indent+2))
		}
		sb.WriteString(prefix + "    OD;\n")

	case ConditionalComposition:
		sb.WriteString(prefix + "IF ")
		sb.WriteString(marshalBoolExpr(v.Condition))
		sb.WriteString(" THEN\n")
		for _, thenOp := range v.ThenOps {
			sb.WriteString(marshalCompositionOp(thenOp, indent+1))
		}
		if len(v.ElseOps) > 0 {
			sb.WriteString(prefix + "ELSE\n")
			for _, elseOp := range v.ElseOps {
				sb.WriteString(marshalCompositionOp(elseOp, indent+1))
			}
		}
		sb.WriteString(prefix + "FI;\n")

	case ForLoop:
		sb.WriteString(prefix)
		fmt.Fprintf(&sb, "FOR %s:", v.Variable)
		start := int(v.Interval.Start.(NumLiteral).Value)
		end := int(v.Interval.End.(NumLiteral).Value)
		fmt.Fprintf(&sb, "[%d..%d]", start, end)
		fmt.Fprintf(&sb, " STEP %d\n", v.Step)
		sb.WriteString(prefix + "    DO\n")
		for _, action := range v.DoBlock.Actions {
			sb.WriteString(marshalSimpleAction(action, indent+2))
		}
		sb.WriteString(prefix + "    OD;\n")

	case MapComposition:
		sb.WriteString(prefix)
		fmt.Fprintf(&sb, "MAP %s ON %s", marshalEventInstance(v.Source), marshalEventInstance(v.Target))
		sb.WriteString("\n")

	default:
		sb.WriteString(prefix + "<unknown_composition>\n")
	}

	return sb.String()
}

// Marshal converts a SimpleAction to .mp text format.
func marshalSimpleAction(action SimpleAction, indent int) string {
	var sb strings.Builder
	prefix := strings.Repeat("    ", indent)

	switch v := action.(type) {
	case AddRelation:
		sb.WriteString(prefix + "ADD ")
		sb.WriteString(marshalRelationDomain(v.RelDomain1))
		sb.WriteString(" ")
		sb.WriteString(marshalRelation(v.Relation))
		for _, domain := range v.RelDomains {
			sb.WriteString(", ")
			sb.WriteString(marshalRelationDomain(domain))
		}
		sb.WriteString("\n")

	case ShareClause:
		sb.WriteString(prefix)
		fmt.Fprintf(&sb, "SHARE %s %s", marshalEventInstance(v.Var1), marshalEventInstance(v.Var2))
		sb.WriteString("\n")

	case EnsureRequest:
		sb.WriteString(prefix + "ENSURE ")
		sb.WriteString(marshalBoolExpr(v.Condition))
		sb.WriteString("\n")

	case AssertionCheck:
		sb.WriteString(prefix + "CHECK ")
		sb.WriteString(marshalBoolExpr(v.Condition))
		sb.WriteString(" ONFAIL SAY(\"")
		if v.OnFailSay != nil {
			sb.WriteString(marshalStringConstructor(v.OnFailSay.String))
		}
		sb.WriteString("\");\n")

	case SAYClause:
		sb.WriteString(prefix + "SAY(\"")
		sb.WriteString(marshalStringConstructor(v.String))
		sb.WriteString("\");\n")

	case AttributeAssignment:
		sb.WriteString(prefix)
		if v.AttributeClass != nil {
			fmt.Fprintf(&sb, "%s.", *v.AttributeClass)
		}
		sb.WriteString(v.Name)
		if v.Op != nil {
			sb.WriteString(string(*v.Op))
		} else {
			sb.WriteString(":=")
		}
		sb.WriteString(marshalAttrExpr(v.Value))
		sb.WriteString("\n")

	case TimingAttributeAdjustment:
		sb.WriteString(prefix + "SET ")
		sb.WriteString(marshalEventInstance(v.Event))
		fmt.Fprintf(&sb, ".%s AT LEAST ", v.Field)
		sb.WriteString(marshalAttrExpr(v.Expr))
		sb.WriteString("\n")

	default:
		sb.WriteString(prefix + "<unknown_action>\n")
	}

	return sb.String()
}

// Marshal converts a ThreadSelection to .mp text format.
func marshalThreadSelection(t ThreadSelection, indent int) string {
	var sb strings.Builder
	prefix := strings.Repeat("    ", indent)

	if t.Variable != nil {
		sb.WriteString(prefix + "$" + *t.Variable + ": ")
	} else {
		sb.WriteString(prefix)
	}

	sb.WriteString(t.EventName)

	if t.From != nil {
		fmt.Fprintf(&sb, " FROM %s", marshalEventInstance(*t.From))
	}

	return sb.String()
}

// Marshal converts a RelationDomain to .mp text format.
func marshalRelationDomain(d RelationDomain) string {
	if d.This {
		return "THIS"
	}
	if d.Event != nil {
		return marshalEventInstance(*d.Event)
	}
	return ""
}

// Marshal converts a Relation to .mp text format.
func marshalRelation(r Relation) string {
	if len(r.Args) > 0 {
		return fmt.Sprintf("%s(%s)", r.Name, strings.Join(r.Args, ", "))
	}
	return r.Name
}

// Marshal converts an EventInstance to .mp text format.
func marshalEventInstance(e EventInstance) string {
	var sb strings.Builder
	if e.Variable != nil {
		sb.WriteString("$" + *e.Variable)
	} else if e.NodeVar != nil {
		sb.WriteString("Node$" + *e.NodeVar)
	}
	sb.WriteString(e.Name)
	return sb.String()
}

// Marshal converts a BoolExpr to .mp text format.
func marshalBoolExpr(expr BoolExpr) string {
	switch v := expr.(type) {
	case BoolLiteral:
		if v.Value {
			return "TRUE"
		}
		return "FALSE"
	case BoolNot:
		return fmt.Sprintf("NOT %s", marshalBoolExpr(v.Expr))
	case BoolAnd:
		return fmt.Sprintf("(%s AND %s)", marshalBoolExpr(v.Left), marshalBoolExpr(v.Right))
	case BoolOr:
		return fmt.Sprintf("(%s OR %s)", marshalBoolExpr(v.Left), marshalBoolExpr(v.Right))
	case BoolImply:
		if v.BiDir {
			return fmt.Sprintf("(%s <--> %s)", marshalBoolExpr(v.Left), marshalBoolExpr(v.Right))
		}
		return fmt.Sprintf("(%s --> %s)", marshalBoolExpr(v.Left), marshalBoolExpr(v.Right))
	case BoolNavigation:
		left := marshalRelationDomain(v.Left)
		right := marshalRelationDomain(v.Right)
		return fmt.Sprintf("%s %s %s", left, v.Direction, right)
	case BoolEquality:
		op := "=="
		if v.NotEq {
			op = "!="
		}
		return fmt.Sprintf("%s %s %s", marshalEventInstance(v.Left), op, marshalEventInstance(v.Right))
	case BoolNumericCompare:
		return fmt.Sprintf("(%s %s %s)",
			marshalNumericExpr(v.Left), v.Operator, marshalNumericExpr(v.Right))
	case BoolMayOverlap:
		return fmt.Sprintf("MAY_OVERLAP %s %s",
			marshalEventInstance(v.Var1), marshalEventInstance(v.Var2))
	case BoolQuantified:
		var sb strings.Builder
		sb.WriteString(v.Quantifier)
		if v.Distinct {
			sb.WriteString(" DISJ")
		}
		for _, pattern := range v.Patterns {
			fmt.Fprintf(&sb, " %s:", pattern.Variable)
			if pattern.SelectionPattern != nil {
				sb.WriteString(*pattern.SelectionPattern)
			}
			if pattern.From != nil {
				fmt.Fprintf(&sb, " FROM %s", marshalEventInstance(*pattern.From))
			}
		}
		sb.WriteString(" ")
		sb.WriteString(marshalBoolExpr(v.Condition))
		return sb.String()
	case BoolAggregate:
		var sb strings.Builder
		fmt.Fprintf(&sb, "%s { ", v.Aggregator)
		sb.WriteString(marshalThreadSelection(v.Thread, 0))
		sb.WriteString(" APPLY ")
		sb.WriteString(marshalBoolExpr(v.Condition))
		sb.WriteString(" }")
		return sb.String()
	default:
		return "<unknown_bool_expr>"
	}
}

// Marshal converts a NumericExpression to .mp text format.
func marshalNumericExpr(expr NumericExpression) string {
	switch v := expr.(type) {
	case NumLiteral:
		if v.IsInt {
			return fmt.Sprintf("%d", int(v.Value))
		}
		return fmt.Sprintf("%.6f", v.Value)
	case NumAdd:
		return fmt.Sprintf("(%s + %s)", marshalNumericExpr(v.Left), marshalNumericExpr(v.Right))
	case NumSub:
		return fmt.Sprintf("(%s - %s)", marshalNumericExpr(v.Left), marshalNumericExpr(v.Right))
	case NumMul:
		return fmt.Sprintf("(%s * %s)", marshalNumericExpr(v.Left), marshalNumericExpr(v.Right))
	case NumDiv:
		return fmt.Sprintf("(%s / %s)", marshalNumericExpr(v.Left), marshalNumericExpr(v.Right))
	default:
		return "<unknown_numeric_expr>"
	}
}

// Marshal converts an AttrExpr to .mp text format.
func marshalAttrExpr(expr AttrExpr) string {
	switch v := expr.(type) {
	case NumAttrExpr:
		return marshalNumericExpr(v.Expr)
	case IntervalAttrExpr:
		return fmt.Sprintf("[%s..%s]",
			marshalNumericExpr(v.Start), marshalNumericExpr(v.End))
	default:
		return "<unknown_attr_expr>"
	}
}

// Marshal converts a StringConstructor to .mp text format.
func marshalStringConstructor(sc StringConstructor) string {
	var parts []string
	for _, part := range sc {
		switch v := part.(type) {
		case StringLiteral:
			parts = append(parts, fmt.Sprintf("\"%s\"", strings.ReplaceAll(v.Value, "\"", "\\\"")))
		case StringExpr:
			parts = append(parts, marshalAttrRef(v.Attr))
		default:
			parts = append(parts, "<unknown_string_part>")
		}
	}
	return strings.Join(parts, " ")
}

// Marshal converts an AttrRef to .mp text format.
func marshalAttrRef(ref AttrRef) string {
	if ref.Class != nil {
		return fmt.Sprintf("%s.%s", *ref.Class, ref.Name)
	}
	return ref.Name
}

// marshalAttributes converts a slice of AttributeDeclaration to .mp text format.
func marshalAttributes(attrs []AttributeDeclaration) string {
	var sb strings.Builder
	sb.WriteString("ATTRIBUTES {\n")
	for _, attr := range attrs {
		fmt.Fprintf(&sb, "    %s %s;\n", attr.Type, attr.Name)
	}
	sb.WriteString("}\n")
	return sb.String()
}

// marshalGraphOp converts a GraphOperation to .mp text format.
func marshalGraphOp(op GraphOperation, indent int) string {
	var sb strings.Builder
	prefix := strings.Repeat("    ", indent)

	switch op.Type {
	case "fill_empty_nest":
		sb.WriteString(prefix + op.NodeVar + ": ")
		if op.StringConst != nil {
			val := *op.StringConst
			fmt.Fprintf(&sb, "%s \"%s\"", val, val)
		} else {
			sb.WriteString("LAST")
		}
		sb.WriteString(";\n")
	case "loop_over_graph":
		sb.WriteString(prefix + fmt.Sprintf("FOR %s DO", op.NodeVar))
		if op.DoBlock != nil {
			for _, action := range op.DoBlock.Actions {
				sb.WriteString(marshalSimpleAction(action, indent+1))
			}
		}
		sb.WriteString("OD;\n")
	default:
		sb.WriteString(prefix + "<unknown_graph_op>\n")
	}

	return sb.String()
}
