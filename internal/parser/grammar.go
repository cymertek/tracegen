// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package parser implements the MP (Modeling Pattern) V4 behavioral event grammar parser.
// This file defines all AST node types used throughout the parser and trace generator.
package parser

import (
	"fmt"
	"strings"
)

// ASTNode is the interface all AST nodes implement for type dispatch.
type ASTNode interface {
	nodeType() string
}

// ParseError represents a parsing error with location information.
type ParseError struct {
	Token   Token
	Message string
}

func (e ParseError) Error() string {
	return fmt.Sprintf("line %d, column %d: %s", e.Token.Line, e.Token.Column, e.Message)
}

// ============================================================
// Top-level schema
// ============================================================

// SchemaNode represents a complete MP program (SCHEMA ...).
type SchemaNode struct {
	Name             string
	Rules            []RuleNode
	Attributes       []AttributeDeclarationNode
	ViewDescriptions []ViewDescriptionNode
	Coordinates      []*CoordinateNode
}

func (s *SchemaNode) nodeType() string { return "schema" }

// Marshal converts SchemaNode to canonical MP text format for content-stable hashing.
func (s *SchemaNode) Marshal() string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("SCHEMA %s\n", s.Name))

	for _, rule := range s.Rules {
		b.WriteString(rule.Marshal())
	}

	if len(s.Attributes) > 0 {
		b.WriteString(marshalAttributes(s.Attributes))
	}

	for _, view := range s.ViewDescriptions {
		b.WriteString(view.Marshal())
	}

	for _, coord := range s.Coordinates {
		b.WriteString(coord.Marshal())
	}

	return b.String()
}

// ============================================================
// Rules and patterns
// ============================================================

// RuleNode represents a named event rule: ROOT? CNAME ":" pattern_list ;
type RuleNode struct {
	Name        string
	PatternList PatternListNode
	BuildBlock  *BuildBlockNode
	Attributes  []AttributeDeclarationNode
	IsRoot      bool
}

func (r *RuleNode) nodeType() string { return "rule" }

// Marshal converts RuleNode to canonical MP text format.
func (r *RuleNode) Marshal() string {
	var b strings.Builder
	if r.IsRoot {
		b.WriteString("ROOT ")
	}
	fmt.Fprintf(&b, "%s: %v;\n", r.Name, r.PatternList)
	return b.String()
}

// marshalAttributes converts attribute declarations to canonical MP text.
func marshalAttributes(attrs []AttributeDeclarationNode) string {
	var b strings.Builder
	for _, attr := range attrs {
		fmt.Fprintf(&b, "ATTRIBUTE %s: %s;\n", attr.Name, attr.Type)
	}
	return b.String()
}

// Marshal converts AttributeDeclarationNode to canonical MP text.
func (a *AttributeDeclarationNode) Marshal() string {
	var b strings.Builder
	fmt.Fprintf(&b, "ATTRIBUTE %s: %s;\n", a.Name, a.Type)
	return b.String()
}

// Marshal converts ViewDescriptionNode to canonical MP text.
func (v *ViewDescriptionNode) Marshal() string {
	var b strings.Builder
	if v.Title != nil {
		fmt.Fprintf(&b, "VIEW %s %q\n", v.Type, *v.Title)
	} else {
		fmt.Fprintf(&b, "VIEW %s\n", v.Type)
	}
	return b.String()
}

// Marshal converts CoordinateNode to canonical MP text.
func (c *CoordinateNode) Marshal() string {
	var b strings.Builder
	b.WriteString("COORDINATE:\n")
	for _, thread := range c.Threads {
		fmt.Fprintf(&b, "  %v\n", thread.String())
	}
	return b.String()
}

// String converts PatternListNode to canonical MP text.
func (p PatternListNode) String() string {
	var b strings.Builder
	b.WriteString("[")
	for i, item := range p {
		if i > 0 {
			b.WriteString(", ")
		}
		fmt.Fprintf(&b, "%v", item)
	}
	b.WriteString("]")
	return b.String()
}

// String converts ThreadSelectionNode to canonical MP text.
func (t *ThreadSelectionNode) String() string {
	var b strings.Builder
	if t.Variable != nil {
		fmt.Fprintf(&b, "$%s: ", *t.Variable)
	} else if t.NodeVar != nil {
		fmt.Fprintf(&b, "Node$%s: ", *t.NodeVar)
	}
	b.WriteString(t.EventName)
	if t.From != nil {
		fmt.Fprintf(&b, " FROM %v", t.From)
	}
	return b.String()
}


// String converts EventInstanceNode to canonical MP text.
func (e *EventInstanceNode) String() string {
	var b strings.Builder
	b.WriteString(e.Name)
	if e.Variable != nil {
		fmt.Fprintf(&b, " $%s", *e.Variable)
	} else if e.NodeVar != nil {
		fmt.Fprintf(&b, " Node$%s", *e.NodeVar)
	}
	return b.String()
}


// String converts AtomicEventNode to canonical MP text.
func (a *AtomicEventNode) String() string {
	var b strings.Builder
	if a.Variable != nil {
		fmt.Fprintf(&b, "$%s: ", *a.Variable)
	} else if a.NodeVar != nil {
		fmt.Fprintf(&b, "Node$%s: ", *a.NodeVar)
	}
	b.WriteString(a.Name)
	return b.String()
}

// String converts AlternativeNode to canonical MP text.
func (a *AlternativeNode) String() string {
	var b strings.Builder
	if a.Probability != nil {
		fmt.Fprintf(&b, "<<%.2f>> ", a.Probability.Value)
	}
	b.WriteString(a.PatternList.String())
	return b.String()
}

// String converts OptionalPatternNode to canonical MP text.
func (o *OptionalPatternNode) String() string {
	var b strings.Builder
	if o.Probability != nil {
		fmt.Fprintf(&b, "<<%.2f>> ", o.Probability.Value)
	}
	b.WriteString("[" + o.PatternList.String() + "]")
	return b.String()
}

// String converts ItPatternNode to canonical MP text.
func (i *ItPatternNode) String() string {
	var b strings.Builder
	if i.Scope != nil {
		fmt.Fprintf(&b, "(%d..%d ", i.Scope.Min, i.Scope.Max)
	} else {
		b.WriteString("(* ")
	}
	b.WriteString(i.PatternList.String())
	if i.Scope != nil {
		b.WriteString(" *)")
	} else {
		b.WriteString(" *)")
	}
	return b.String()
}

// String converts ListPatternNode to canonical MP text.
func (l *ListPatternNode) String() string {
	var b strings.Builder
	if l.Bounded {
		fmt.Fprintf(&b, "(%d..%d ", l.Min, l.Max)
	} else {
		b.WriteString("+ ")
	}
	for i, item := range l.Items {
		if i > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "%v", item)
	}
	if l.Bounded {
		b.WriteString(" *)")
	} else {
		b.WriteString(" +")
	}
	return b.String()
}

// String converts SetPatternNode to canonical MP text.
func (s *SetPatternNode) String() string {
	var b strings.Builder
	if s.Bounded {
		fmt.Fprintf(&b, "{%d..%d ", s.Min, s.Max)
	} else {
		b.WriteString("{+ ")
	}
	for i, item := range s.Items {
		if i > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "%v", item)
	}
	if s.Bounded {
		b.WriteString(" }")
	} else {
		b.WriteString(" +}")
	}
	return b.String()
}

// String converts ItPlusPatternNode to canonical MP text.
func (itp *ItPlusPatternNode) String() string {
	var b strings.Builder
	if itp.Scope != nil {
		fmt.Fprintf(&b, "(%d..%d ", itp.Scope.Min, itp.Scope.Max)
	} else {
		b.WriteString("+ ")
	}
	fmt.Fprintf(&b, "%v", itp.Item)
	for _, item := range itp.PatternList {
		fmt.Fprintf(&b, " | %v", item)
	}
	if itp.Scope != nil {
		b.WriteString(" *)")
	} else {
		b.WriteString(" +")
	}
	return b.String()
}

// String converts SetItPatternNode to canonical MP text.
func (si *SetItPatternNode) String() string {
	var b strings.Builder
	if si.Scope != nil {
		fmt.Fprintf(&b, "{%d..%d ", si.Scope.Min, si.Scope.Max)
	} else {
		b.WriteString("{+ ")
	}
	for i, item := range si.Items {
		if i > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "%v", item)
	}
	if si.Scope != nil {
		b.WriteString(" }")
	} else {
		b.WriteString(" +}")
	}
	return b.String()
}

// String converts SetItPlusPatternNode to canonical MP text.
func (sip *SetItPlusPatternNode) String() string {
	var b strings.Builder
	fmt.Fprintf(&b, "{+ %v", sip.Item)
	for _, item := range sip.Items {
		fmt.Fprintf(&b, " | %v", item)
	}
	b.WriteString(" +}")
	return b.String()
}

// String converts AltGroupNode to canonical MP text.
func (a *AltGroupNode) String() string {
	var b strings.Builder
	for i, alt := range a.Alternatives {
		if i > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "%v", alt)
	}
	return b.String()
}

// String converts ProbabilityNode to canonical MP text.
func (p *ProbabilityNode) String() string {
	return fmt.Sprintf("%.4f", p.Value)
}

// String converts IterationScopeNode to canonical MP text.
func (i *IterationScopeNode) String() string {
	if i != nil {
		return fmt.Sprintf("%d..%d", i.Min, i.Max)
	}
	return ""
}

// BuildBlockNode represents a BUILD block with composition operations and optional nested coordinates.
type BuildBlockNode struct {
	Operations        []CompositionOpNode
	NestedCoordinates []*CoordinateNode // nested COORDINATE blocks inside BUILD
}

func (b *BuildBlockNode) nodeType() string { return "build_block" }

// PatternListNode is a sequence of pattern units.
type PatternListNode []PatternUnitNode

func (p PatternListNode) nodeType() string { return "pattern_list" }

// PatternUnitNode is the interface for all pattern units.
type PatternUnitNode interface {
	ASTNode
	patternUnitType() string
}

// AtomicEventNode represents an atomic event: EventName or $var: EventName.
type AtomicEventNode struct {
	Name        string
	Probability *ProbabilityNode
	Reshuffle   *string
	Variable    *string // optional variable binding ($x, $y)
	NodeVar     *string // optional node-scoped variable (Node$x)
}

func (a *AtomicEventNode) nodeType() string        { return "atomic_event" }
func (a *AtomicEventNode) patternUnitType() string { return "ATOM" }

// AltGroupNode represents an alternative group with probabilities.
type AltGroupNode struct {
	Alternatives []AlternativeNode
}

func (a *AltGroupNode) nodeType() string        { return "alt_group" }
func (a *AltGroupNode) patternUnitType() string { return "ALT_GROUP" }

// AlternativeNode represents one branch in an alt_group.
type AlternativeNode struct {
	Probability *ProbabilityNode
	PatternList PatternListNode
}

func (a *AlternativeNode) nodeType() string { return "alternative" }

// ListPatternNode represents iteration patterns: (* ... *) or + ... +.
type ListPatternNode struct {
	Bounded bool // true for (* ... *), false for + ... +
	Min     int
	Max     int
	Items   []PatternUnitNode
}

func (l *ListPatternNode) nodeType() string        { return "list_pattern" }
func (l *ListPatternNode) patternUnitType() string { return "LIST" }

// SetPatternNode represents unordered collections: { ... }.
type SetPatternNode struct {
	Bounded bool // true for set_it, false for set_it_plus
	Min     int
	Max     int
	Items   []PatternUnitNode
}

func (s *SetPatternNode) nodeType() string        { return "set_pattern" }
func (s *SetPatternNode) patternUnitType() string { return "SET" }

// OptionalPatternNode represents optional events [ ... ].
type OptionalPatternNode struct {
	Probability *ProbabilityNode
	PatternList PatternListNode
}

func (o *OptionalPatternNode) nodeType() string        { return "optional_pattern" }
func (o *OptionalPatternNode) patternUnitType() string { return "OPTIONAL" }

// ItPatternNode represents bounded iteration with scope: (* <min..max> pattern_list *).
type ItPatternNode struct {
	Scope       *IterationScopeNode
	PatternList PatternListNode
}

func (i *ItPatternNode) nodeType() string        { return "it_pattern" }
func (i *ItPatternNode) patternUnitType() string { return "IT" }

// ItPlusPatternNode represents unbounded iteration: + pattern_unit pattern_list +.
type ItPlusPatternNode struct {
	Scope       *IterationScopeNode // optional bounded scope
	Item        PatternUnitNode
	PatternList PatternListNode
}

func (itp *ItPlusPatternNode) nodeType() string        { return "it_plus_pattern" }
func (itp *ItPlusPatternNode) patternUnitType() string { return "IT_PLUS" }

// SetItPatternNode represents bounded set iteration.
type SetItPatternNode struct {
	Scope *IterationScopeNode
	Items []PatternUnitNode
}

func (si *SetItPatternNode) nodeType() string        { return "set_it_pattern" }
func (si *SetItPatternNode) patternUnitType() string { return "SET_IT" }

// SetItPlusPatternNode represents unbounded set iteration.
type SetItPlusPatternNode struct {
	Item  PatternUnitNode
	Items []PatternUnitNode
}

func (sip *SetItPlusPatternNode) nodeType() string        { return "set_it_plus_pattern" }
func (sip *SetItPlusPatternNode) patternUnitType() string { return "SET_IT_PLUS" }

// ProbabilityNode represents a probabilistic annotation.
type ProbabilityNode struct {
	Value float64
}

func (p *ProbabilityNode) nodeType() string { return "probability" }

// IterationScopeNode defines bounds for iterations: <min..max>.
type IterationScopeNode struct {
	Min int
	Max int // -1 means unbounded
}

func (i *IterationScopeNode) nodeType() string { return "iteration_scope" }

// ============================================================
// Attributes and views
// ============================================================

// AttributeDeclarationNode represents an attribute type declaration.
type AttributeDeclarationNode struct {
	Name string
	Type string // "NUMBER", "INTERVAL", "BOOLEAN"
}

func (a *AttributeDeclarationNode) nodeType() string { return "attribute_declaration" }

// AttributeType constants for attribute declarations.
const (
	AttributeTypeNumber   = "NUMBER"
	AttributeTypeInterval = "INTERVAL"
	AttributeTypeBoolean  = "BOOLEAN"
)

// ViewDescriptionNode represents a view definition (REPORT, GRAPH, TABLE, BAR CHART).
type ViewDescriptionNode struct {
	Type       string // "REPORT", "GRAPH", "TABLE", "BAR"
	Name       string
	Title      *string
	Tabs       [][]string
	XAxis      *string
	Rotate     bool
	Operations []GraphOperationNode
}

func (v *ViewDescriptionNode) nodeType() string { return "view_description" }

// GraphOperationNode represents operations within a WITHIN block.
type GraphOperationNode struct {
	Type        string // "fill_empty_nest", "loop_over_graph"
	NodeVar     string
	StringConst *string
	DoBlock     *DOBlockNode
}

func (g *GraphOperationNode) nodeType() string { return "graph_operation" }

// ============================================================
// Coordinate blocks and composition operations
// ============================================================

// CoordinateNode represents a COORDINATE block with threads and DO/OD.
type CoordinateNode struct {
	NestedCoords   []*CoordinateNode // nested coordinates within DO blocks
	Modifiers      []string          // e.g., "REVERSE" for <REVERSE> modifier
	Threads    []ThreadSelectionNode
	Operations []CompositionOpNode
}

func (c *CoordinateNode) nodeType() string { return "coordinate" }

// ThreadSelectionNode represents thread selection in COORDINATE blocks: $x: CNAME FROM root OR THIS.
type ThreadSelectionNode struct {
	Variable  *string            // optional variable binding ($x, $y)
	NodeVar   *string            // optional node-scoped variable (Node$x)
	EventName string             // event name being selected
	From      *EventInstanceNode // optional FROM clause
}

func (t *ThreadSelectionNode) nodeType() string { return "thread_selection" }

// EventInstanceNode represents an event reference in the grammar.
type EventInstanceNode struct {
	Name     string
	Variable *string // optional variable binding ($x, $y)
	NodeVar  *string // optional node-scoped variable (Node$x)
}

func (e *EventInstanceNode) nodeType() string { return "event_instance" }

// CompositionOpNode represents a composition operation within COORDINATE blocks.
// This is the concrete struct used by CoordinateNode.Operations and BuildBlockNode.Operations.
type CompositionOpNode struct {
	Type          string // "ADD", "ENSURE", "IF_THEN_ELSE", "FOR_LOOP", "MAP", "SAY", "CHECK", "ONFAIL", "SET"
	RelationName  string // relation name for ADD (e.g., "PRECEDES")
	LeftVariable  string
	RightVariable string
	Variable      string      // variable being set in SET operations
	Expression    interface{} // BoolExprNode or numeric expression
	Condition     interface{} // BoolExprNode from IF condition
	ThenBranch    []CompositionOpNode
	ElseBranch    []CompositionOpNode
	LoopVariable  string
	LoopStart     interface{} // NumericExpressionNode
	LoopEnd       interface{} // NumericExpressionNode
	LoopStep      interface{} // NumericExpressionNode
	LoopBody      []CompositionOpNode
	MapVariable   string
	Collection    interface{} // expression
	NestedCoordinate *CoordinateNode // for nested COORDINATE operations
	MapBody       []CompositionOpNode
	Message       string
	FailureAction *CompositionOpNode
}

func (c *CompositionOpNode) nodeType() string { return "composition_op" }

// DOBlockNode contains a sequence of simple actions within COORDINATE/FOR/IF blocks.
type DOBlockNode struct {
	Actions []SimpleActionNode
}

func (d *DOBlockNode) nodeType() string { return "do_block" }

// SimpleActionNode is the interface for all simple actions within DO blocks.
type SimpleActionNode interface {
	ASTNode
	simpleActionType() string
}

// AddRelationNode represents ADD relation_domain relation relation_domain(COMMA ...)*.
type AddRelationNode struct {
	RelDomain1 RelationDomainNode
	Relation   RelationNode
	RelDomains []RelationDomainNode // additional domains for multi-relations
}

func (a *AddRelationNode) nodeType() string         { return "add_relation" }
func (a *AddRelationNode) simpleActionType() string { return "ADD_RELATION" }

// ShareClauseNode represents SHARE variable variable equality constraint.
type ShareClauseNode struct {
	Var1 EventInstanceNode
	Var2 EventInstanceNode
}

func (s *ShareClauseNode) nodeType() string         { return "share_clause" }
func (s *ShareClauseNode) simpleActionType() string { return "SHARE_CLAUSE" }

// EnsureRequestNode represents ENSURE bool_expr declarative constraint.
type EnsureRequestNode struct {
	Condition BoolExprNode
}

func (e *EnsureRequestNode) nodeType() string         { return "ensure_request" }
func (e *EnsureRequestNode) simpleActionType() string { return "ENSURE" }

// AssertionCheckNode represents CHECK bool_expr ONFAIL SAY(string_constructor).
type AssertionCheckNode struct {
	Condition BoolExprNode
	OnFailSay *SAYClauseNode
}

func (a *AssertionCheckNode) nodeType() string         { return "assertion_check" }
func (a *AssertionCheckNode) simpleActionType() string { return "ASSERTION_CHECK" }

// SAYClauseNode represents SAY "string_constructor" trace annotation.
type SAYClauseNode struct {
	String StringConstructorNode
}

func (s *SAYClauseNode) nodeType() string         { return "say_clause" }
func (s *SAYClauseNode) simpleActionType() string { return "SAY" }

// RelationDomainNode represents the left-hand side of a relation (event instance or THIS).
type RelationDomainNode struct {
	Event *EventInstanceNode // nil if THIS
	This  bool               // true if referencing THIS
}

func (r *RelationDomainNode) nodeType() string { return "relation_domain" }

// RelationNode is one of: PRECEDES, IN, user-defined relations.
type RelationNode struct {
	Name string   // "PRECEDES", "IN", or user-defined relation name
	Args []string // arguments for arrow/line constructors (e.g., ["left_neighbor_of"])
}

func (r *RelationNode) nodeType() string { return "relation" }

// ============================================================
// Boolean expressions
// ============================================================

// BoolExprNode is the interface for boolean expressions.
type BoolExprNode interface {
	ASTNode
	boolExprType() string
}

// BoolLiteralNode is TRUE or FALSE.
type BoolLiteralNode struct {
	Value bool
}

func (b *BoolLiteralNode) nodeType() string     { return "bool_literal" }
func (b *BoolLiteralNode) boolExprType() string { return "LITERAL" }

// BoolNotNode is NOT expr.
type BoolNotNode struct {
	Expr BoolExprNode
}

func (b *BoolNotNode) nodeType() string     { return "bool_not" }
func (b *BoolNotNode) boolExprType() string { return "NOT" }

// BoolAndNode is expr AND expr.
type BoolAndNode struct {
	Left  BoolExprNode
	Right BoolExprNode
}

func (b *BoolAndNode) nodeType() string     { return "bool_and" }
func (b *BoolAndNode) boolExprType() string { return "AND" }

// BoolOrNode is expr OR expr.
type BoolOrNode struct {
	Left  BoolExprNode
	Right BoolExprNode
}

func (b *BoolOrNode) nodeType() string     { return "bool_or" }
func (b *BoolOrNode) boolExprType() string { return "OR" }

// BoolImplyNode is expr IMPLIES expr or expr <--> expr.
type BoolImplyNode struct {
	Left  BoolExprNode
	Right BoolExprNode
	BiDir bool // true for <--> biconditional, false for --> implication
}

func (b *BoolImplyNode) nodeType() string     { return "bool_imply" }
func (b *BoolImplyNode) boolExprType() string { return "IMPLY" }

// BoolNavigationNode is directional comparison: (CNAME | variable | THIS) navigation_direction (...).
type BoolNavigationNode struct {
	Left      RelationDomainNode
	Direction string // IN, PRECEDES, ENCLOSING, FROM, CONTAINS, FOLLOWS, BEFORE, AFTER, or user-defined
	Right     RelationDomainNode
}

func (b *BoolNavigationNode) nodeType() string     { return "bool_navigation" }
func (b *BoolNavigationNode) boolExprType() string { return "NAVIGATION" }

// BoolEqualityNode is variable == variable or variable != variable.
type BoolEqualityNode struct {
	Left  EventInstanceNode
	Right EventInstanceNode
	NotEq bool // true for !=, false for ==
}

func (b *BoolEqualityNode) nodeType() string     { return "bool_equality" }
func (b *BoolEqualityNode) boolExprType() string { return "EQUALITY" }

// BoolNumericCompareNode is numeric_expression comparison numeric_expression.
type BoolNumericCompareNode struct {
	Left     NumericExpressionNode
	Operator string // "<", "<=", ">", ">="
	Right    NumericExpressionNode
}

func (b *BoolNumericCompareNode) nodeType() string     { return "bool_numeric_compare" }
func (b *BoolNumericCompareNode) boolExprType() string { return "NUMERIC_COMPARE" }

// BoolMayOverlapNode is MAY_OVERLAP variable variable.
type BoolMayOverlapNode struct {
	Var1 EventInstanceNode
	Var2 EventInstanceNode
}

func (b *BoolMayOverlapNode) nodeType() string     { return "bool_may_overlap" }
func (b *BoolMayOverlapNode) boolExprType() string { return "MAY_OVERLAP" }

// BoolQuantifiedNode represents FOREACH|EXISTS DISJ? variable_selection_pattern* bool_expr.
type BoolQuantifiedNode struct {
	Quantifier string // "FOREACH" or "EXISTS"
	Distinct   bool   // true if DISJ is present
	Patterns   []VarSelectionPatternNode
	Condition  BoolExprNode
}

func (b *BoolQuantifiedNode) nodeType() string     { return "bool_quantified" }
func (b *BoolQuantifiedNode) boolExprType() string { return "QUANTIFIED" }

// VarSelectionPatternNode represents variable ":" selection_pattern ("FROM" event_instance)?.
type VarSelectionPatternNode struct {
	Variable         string
	SelectionPattern *string            // optional selection pattern name
	From             *EventInstanceNode // optional FROM clause
}

func (v *VarSelectionPatternNode) nodeType() string { return "var_selection_pattern" }

// BoolAggregateNode represents (OR|AND) "{" thread APPLY bool_expr "}".
type BoolAggregateNode struct {
	Aggregator string // "OR" or "AND"
	Thread     ThreadSelectionNode
	Condition  BoolExprNode
}

func (b *BoolAggregateNode) nodeType() string     { return "bool_aggregate" }
func (b *BoolAggregateNode) boolExprType() string { return "AGGREGATE" }

// ============================================================
// Numeric expressions and attributes
// ============================================================

// NumExprNode represents a binary numeric expression: left op right.
type NumExprNode struct {
	Left     interface{} // left operand
	Operator string      // "+", "-"
	Right    interface{} // right operand
}

func (n *NumExprNode) nodeType() string     { return "num_expr" }
func (n *NumExprNode) numericType() string  { return "BINARY" }
func (n *NumExprNode) boolExprType() string { return "NUM_AS_BOOL" }

// CountExpr represents #event_name [FROM source] expression for counting events.
type CountExpr struct {
	EventName string             // event name being counted
	Scope     *EventInstanceNode // optional FROM clause for scope filtering
}

func (c *CountExpr) nodeType() string     { return "count_expr" }
func (c *CountExpr) numericType() string  { return "COUNT" }
func (c *CountExpr) boolExprType() string { return "NUM_AS_BOOL" } // count can be used in boolean context

// VarRefExpr represents a variable reference ($x, Node$x).
type VarRefExpr struct {
	Value string             // variable name without $ prefix
	Scope *EventInstanceNode // optional FROM clause for scope filtering
}

func (v *VarRefExpr) nodeType() string     { return "var_ref" }
func (v *VarRefExpr) numericType() string  { return "VARIABLE" }
func (v *VarRefExpr) boolExprType() string { return "VAR_AS_BOOL" }

// NumLitExpr represents a numeric literal.
type NumLitExpr struct {
	Value float64
}

func (n *NumLitExpr) nodeType() string     { return "num_lit" }
func (n *NumLitExpr) numericType() string  { return "LITERAL" }
func (n *NumLitExpr) boolExprType() string { return "NUM_AS_BOOL" }

// BoolLitExpr represents a boolean literal (TRUE/FALSE).
type BoolLitExpr struct {
	Value bool
}

func (b *BoolLitExpr) nodeType() string    { return "bool_lit" }
func (b *BoolLitExpr) numericType() string { return "LITERAL" }

// NumericExpressionNode is the interface for numeric expressions.
type NumericExpressionNode interface {
	ASTNode
	numericType() string
}

// NumLiteralNode is a numeric constant (integer or float).
type NumLiteralNode struct {
	Value float64
	IsInt bool // true if integer, false if float
}

func (n *NumLiteralNode) nodeType() string    { return "num_literal" }
func (n *NumLiteralNode) numericType() string { return "LITERAL" }

// NumAddNode is expr + expr.
type NumAddNode struct {
	Left  NumericExpressionNode
	Right NumericExpressionNode
}

func (n *NumAddNode) nodeType() string    { return "num_add" }
func (n *NumAddNode) numericType() string { return "ADD" }

// NumSubNode is expr - expr.
type NumSubNode struct {
	Left  NumericExpressionNode
	Right NumericExpressionNode
}

func (n *NumSubNode) nodeType() string    { return "num_sub" }
func (n *NumSubNode) numericType() string { return "SUB" }

// NumMulNode is expr * expr.
type NumMulNode struct {
	Left  NumericExpressionNode
	Right NumericExpressionNode
}

func (n *NumMulNode) nodeType() string    { return "num_mul" }
func (n *NumMulNode) numericType() string { return "MUL" }

// NumDivNode is expr / expr.
type NumDivNode struct {
	Left  NumericExpressionNode
	Right NumericExpressionNode
}

func (n *NumDivNode) nodeType() string    { return "num_div" }
func (n *NumDivNode) numericType() string { return "DIV" }

// IntervalConstructorNode represents [numeric_expression ".." numeric_expression].
type IntervalConstructorNode struct {
	Start NumericExpressionNode
	End   NumericExpressionNode
}

func (i *IntervalConstructorNode) nodeType() string { return "interval_constructor" }

// StringConstructorNode represents a concatenation of strings and expressions for SAY clauses.
type StringConstructorNode []StringPartNode

func (s StringConstructorNode) nodeType() string { return "string_constructor" }

// StringPartNode is one element in a string constructor (literal or expression).
type StringPartNode interface {
	ASTNode
	partType() string
}

// StringLiteralNode is a quoted string constant.
type StringLiteralNode struct {
	Value string
}

func (s *StringLiteralNode) nodeType() string { return "string_literal" }
func (s *StringLiteralNode) partType() string { return "LITERAL" }

// StringExprNode is an attribute reference in a string constructor.
type StringExprNode struct {
	Attr AttrRefNode
}

func (s *StringExprNode) nodeType() string { return "string_expr" }
func (s *StringExprNode) partType() string { return "EXPR" }

// AttrRefNode represents an attribute reference: (attribute_class ".")? CNAME.
type AttrRefNode struct {
	Class *string // optional class like "number", "interval", "bool"
	Name  string
}

func (a *AttrRefNode) nodeType() string { return "attr_ref" }

// AttributeAssignmentNode represents (attribute_class ".")? CNAME attribute_ops? := attribute_expr.
type AttributeAssignmentNode struct {
	AttributeClass *string // optional, e.g., "number", "interval", "bool"
	Name           string
	Op             AttrOpNode   // compound assignment operator
	Value          AttrExprNode // right-hand side expression
}

func (a *AttributeAssignmentNode) nodeType() string         { return "attribute_assignment" }
func (a *AttributeAssignmentNode) simpleActionType() string { return "ATTRIBUTE_ASSIGNMENT" }

// TimingAttributeAdjustmentNode represents SET event_instance.timing AT LEAST timing_expr.
type TimingAttributeAdjustmentNode struct {
	Event EventInstanceNode
	Field string // "start", "end", "duration"
	Expr  AttrExprNode
}

func (t *TimingAttributeAdjustmentNode) nodeType() string         { return "timing_attribute_adjustment" }
func (t *TimingAttributeAdjustmentNode) simpleActionType() string { return "TIMING_ADJUSTMENT" }

// ============================================================
// Attribute expression and operation types
// ============================================================

// AttrExprNode is the interface for attribute expressions.
type AttrExprNode interface {
	ASTNode
	attrType() string
}

// NumAttrExprNode is a numeric expression used as an attribute value.
type NumAttrExprNode struct {
	Expr NumericExpressionNode
}

func (n *NumAttrExprNode) nodeType() string { return "num_attr_expr" }
func (n *NumAttrExprNode) attrType() string { return "NUM" }

// IntervalAttrExprNode is an interval constructor [expr..expr].
type IntervalAttrExprNode struct {
	Start NumericExpressionNode
	End   NumericExpressionNode
}

func (i *IntervalAttrExprNode) nodeType() string { return "interval_attr_expr" }
func (i *IntervalAttrExprNode) attrType() string { return "INTERVAL" }

// AttrOpNode represents compound assignment operators: :=, +=, -=, *=, /=, MIN=, MAX=.
type AttrOpNode string

const (
	AttrAssignNode AttrOpNode = ":="
	AttrAddNode    AttrOpNode = "+="
	AttrSubNode    AttrOpNode = "-="
	AttrMulNode    AttrOpNode = "*="
	AttrDivNode    AttrOpNode = "/="
	AttrMinNode    AttrOpNode = "MIN="
	AttrMaxNode    AttrOpNode = "MAX="
)

func (a AttrOpNode) nodeType() string { return "attr_op" }

// ============================================================
// Utility helpers for AST nodes
// ============================================================

// String returns a human-readable name for the token type used in error messages.
func TokenTypeName(t TokenType) string {
	switch t {
	case TOKEN_SCHEMA:
		return "'SCHEMA'"
	case TOKEN_ROOT:
		return "'ROOT'"
	case TOKEN_COORDINATE:
		return "'COORDINATE'"
	case TOKEN_ADD:
		return "'ADD'"
	case TOKEN_ENSURE:
		return "'ENSURE'"
	case TOKEN_IF:
		return "'IF'"
	case TOKEN_THEN:
		return "'THEN'"
	case TOKEN_ELSE:
		return "'ELSE'"
	case TOKEN_FI:
		return "'FI'"
	case TOKEN_FOR:
		return "'FOR'"
	case TOKEN_STEP:
		return "'STEP'"
	case TOKEN_FROM:
		return "'FROM'"
	case TOKEN_DO:
		return "'DO'"
	case TOKEN_OD:
		return "'OD'"
	case TOKEN_ATTRIBUTES:
		return "'ATTRIBUTES'"
	case TOKEN_BUILD:
		return "'BUILD'"
	default:
		return fmt.Sprintf("token type %d", t)
	}
}
