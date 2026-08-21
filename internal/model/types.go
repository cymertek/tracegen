// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package model defines the core data structures for representing MP language programs.
// These types form the AST (Abstract Syntax Tree) that can be marshaled/unmarshaled to/from .mp text format.
package model

// Schema represents the top-level container for an MP program.
type Schema struct {
	Name             string
	Rules            []Rule
	Attributes       []AttributeDeclaration
	ViewDescriptions []ViewDescription
}

// Rule represents a named event rule with optional build block.
type Rule struct {
	Name        string
	PatternList PatternList
	BuildBlock  *BuildBlock
	IsRoot      bool // true if this is a ROOT rule
}

// BuildBlock contains imperative operations executed during trace generation.
type BuildBlock struct {
	Operations []CompositionOperation
}

// ViewDescription represents REPORT, GRAPH, TABLE, or BAR CHART view definitions.
type ViewDescription struct {
	Type       string // "REPORT", "GRAPH", "TABLE", "BAR"
	Name       string
	Title      *string
	Tabs       [][]string
	XAxis      *string
	Rotate     bool
	Operations []GraphOperation
}

// GraphOperation represents operations within a WITHIN block.
type GraphOperation struct {
	Type        string // "fill_empty_nest", "loop_over_graph"
	NodeVar     string
	StringConst *string
	DoBlock     *DOBlock
}

// PatternList is a sequence of event patterns forming a behavioral expression.
type PatternList []EventPattern

// EventPattern represents a single event in a pattern list (atomic or composite).
type EventPattern struct {
	Name        string
	Variable    string // optional variable binding ($x, $y) - stored without $ prefix
	NodeVar     string // optional node-scoped variable (Node$x) - stored without Node$ prefix
	Probability *float64
}

// Probability represents a probabilistic annotation like <<0.75>>.
type Probability struct {
	Value float64
}

// AltGroup represents alternative choices with optional probabilities.
type AltGroup struct {
	Alternatives []Alternative
}

// Alternative is one branch in an alt_group.
type Alternative struct {
	Probability *Probability
	PatternList PatternList
}

// ListPattern represents iteration patterns: (* ... *) or + ... +.
type ListPattern struct {
	Bounded bool // true for (* ... *), false for + ... +
	Min     int
	Max     int
	Items   []PatternUnit
}

// SetPattern represents unordered collections: { ... }.
type SetPattern struct {
	Bounded bool // true for set_it, false for set_it_plus
	Min     int
	Max     int
	Items   []PatternUnit
}

// OptionalPattern represents optional events [ ... ].
type OptionalPattern struct {
	Probability *Probability
	PatternList PatternList
}

// ItPattern represents bounded iteration with scope: (* <min..max> pattern_list *).
type ItPattern struct {
	Scope       *IterationScope
	PatternList PatternList
}

// ItPlusPattern represents unbounded iteration: + pattern_unit pattern_list +.
type ItPlusPattern struct {
	Item        PatternUnit
	PatternList PatternList
}

// SetItPattern represents bounded set iteration.
type SetItPattern struct {
	Scope *IterationScope
	Items []PatternUnit
}

// SetItPlusPattern represents unbounded set iteration.
type SetItPlusPattern struct {
	Item  PatternUnit
	Items []PatternUnit
}

// IterationScope defines bounds for iterations: <min..max>.
type IterationScope struct {
	Min int
	Max int // -1 means unbounded
}

// AttributeDeclaration represents ATTRIBUTES block with type definitions.
type AttributeDeclaration struct {
	Name string
	Type string // "NUMBER", "INTERVAL", "BOOLEAN"
}

// CompositionOperation is the interface for all composition operations (COORDINATE, FOR, IF, etc.).
type CompositionOperation interface {
	OpType() string
}

// SharedComposition represents SHARE ALL events across roots.
type SharedComposition struct {
	Variables []string // variables being shared
	Events    []string // event names being shared
}

func (s SharedComposition) OpType() string { return "SHARE" }

// AsyncCoordinateOp represents asynchronous coordination: COORDINATE <!> thread DO ... OD.
type AsyncCoordinateOp struct {
	Thread  ThreadSelection
	DoBlock *DOBlock
}

func (a AsyncCoordinateOp) OpType() string { return "ASYNC_COORDINATE" }

// LockstepCoordinateOp represents synchronous coordination: COORDINATE thread(COMMA thread)* DO ... OD.
type LockstepCoordinateOp struct {
	Threads []ThreadSelection
	DoBlock *DOBlock
}

func (l LockstepCoordinateOp) OpType() string { return "LOCKSTEP_COORDINATE" }

// ConditionalComposition represents IF/THEN/ELSE/FI blocks.
type ConditionalComposition struct {
	Condition BoolExpr
	ThenOps   []CompositionOperation
	ElseOps   []CompositionOperation // may be nil for no ELSE clause
}

func (c ConditionalComposition) OpType() string { return "CONDITIONAL" }

// ForLoop represents FOR numeric_variable ":" interval STEP N DO ... OD.
type ForLoop struct {
	Variable string
	Interval IntervalConstructor
	Step     int
	DoBlock  *DOBlock
}

func (f ForLoop) OpType() string { return "FOR_LOOP" }

// MapComposition represents MAP event_instance ON event_instance isomorphism.
type MapComposition struct {
	Source EventInstance
	Target EventInstance
}

func (m MapComposition) OpType() string { return "MAP" }

// DOBlock contains a sequence of simple actions within COORDINATE/FOR/IF blocks.
type DOBlock struct {
	Actions []SimpleAction
}

// SimpleAction is the interface for all simple actions within DO blocks.
type SimpleAction interface {
	ActionType() string
}

// AddRelation represents ADD relation_domain relation relation_domain(COMMA ...)*.
type AddRelation struct {
	RelDomain1 RelationDomain
	Relation   Relation
	RelDomains []RelationDomain // additional domains for multi-relations
}

func (a AddRelation) ActionType() string { return "ADD_RELATION" }
func (a AddRelation) OpType() string     { return "ADD" }

// ShareClause represents SHARE variable variable equality constraint.
type ShareClause struct {
	Var1 EventInstance
	Var2 EventInstance
}

func (s ShareClause) ActionType() string { return "SHARE_CLAUSE" }

// EnsureRequest represents ENSURE bool_expr declarative constraint.
type EnsureRequest struct {
	Condition BoolExpr
}

func (e EnsureRequest) ActionType() string { return "ENSURE" }
func (e EnsureRequest) OpType() string     { return "ENSURE" }

// AssertionCheck represents CHECK bool_expr ONFAIL SAY(string_constructor).
type AssertionCheck struct {
	Condition BoolExpr
	OnFailSay *SAYClause
}

func (a AssertionCheck) ActionType() string { return "ASSERTION_CHECK" }

// SAYClause represents SAY "string_constructor" trace annotation.
type SAYClause struct {
	String StringConstructor
}

func (s SAYClause) ActionType() string { return "SAY" }

// AttributeAssignment represents (attribute_class ".")? CNAME attribute_ops? := attribute_expr.
type AttributeAssignment struct {
	AttributeClass *string // optional, e.g., "number", "interval", "bool"
	Name           string
	Op             *AttrOp  // optional compound assignment operator
	Value          AttrExpr // right-hand side expression
}

func (a AttributeAssignment) ActionType() string { return "ATTRIBUTE_ASSIGNMENT" }

// TimingAttributeAdjustment represents SET event_instance.timing AT LEAST timing_expr.
type TimingAttributeAdjustment struct {
	Event EventInstance
	Field string // "start", "end", "duration"
	Expr  AttrExpr
}

func (t TimingAttributeAdjustment) ActionType() string { return "TIMING_ADJUSTMENT" }

// RelationDomain represents the left-hand side of a relation (event instance or THIS).
type RelationDomain struct {
	Event *EventInstance // nil if THIS
	This  bool           // true if referencing THIS
}

// Relation is one of: PRECEDES, IN, user-defined relations.
type Relation struct {
	Name string   // "PRECEDES", "IN", or user-defined relation name
	Args []string // arguments for arrow/line constructors (e.g., ["left_neighbor_of"])
}

// EventInstance represents an event reference in the grammar.
type EventInstance struct {
	Name     string
	Variable *string // optional variable binding ($x, $y)
	NodeVar  *string // optional node-scoped variable (Node$x)
}

// PatternUnit is a single element in a pattern list.
type PatternUnit interface {
	PatternType() string
}

// AtomicEvent represents an atomic event (leaf node).
type AtomicEvent struct {
	Name        string
	Probability *Probability // optional probability annotation
	Reshuffle   *string      // optional reshuffle operator like <SHIFT_LEFT>
}

func (a AtomicEvent) PatternType() string { return "ATOM" }

// CompositeEventInstance represents a composite event instance placeholder.
type CompositeEventInstance struct {
	Name  string
	Index int // segment version number
}

func (c CompositeEventInstance) PatternType() string { return "COMPOSITE_INSTANCE" }

// ThreadSelection represents thread selection in COORDINATE blocks: $x: CNAME FROM root OR THIS.
type ThreadSelection struct {
	Variable  *string        // optional variable binding ($x, $y)
	EventName string         // event name being selected
	From      *EventInstance // optional FROM clause
}

// BoolExpr represents boolean expressions in ENSURE/IF/CHECK statements.
type BoolExpr interface {
	BoolType() string
}

// BoolLiteral is TRUE or FALSE.
type BoolLiteral struct {
	Value bool
}

func (b BoolLiteral) BoolType() string { return "LITERAL" }

// BoolNot is NOT expr.
type BoolNot struct {
	Expr BoolExpr
}

func (b BoolNot) BoolType() string { return "NOT" }

// BoolAnd is expr AND expr.
type BoolAnd struct {
	Left  BoolExpr
	Right BoolExpr
}

func (b BoolAnd) BoolType() string { return "AND" }

// BoolOr is expr OR expr.
type BoolOr struct {
	Left  BoolExpr
	Right BoolExpr
}

func (b BoolOr) BoolType() string { return "OR" }

// BoolImply is expr IMPLIES expr or expr <--> expr.
type BoolImply struct {
	Left  BoolExpr
	Right BoolExpr
	BiDir bool // true for <--> biconditional, false for --> implication
}

func (b BoolImply) BoolType() string { return "IMPLY" }

// BoolNavigation is directional comparison: (CNAME | variable | THIS) navigation_direction (CNAME | variable | THIS).
type BoolNavigation struct {
	Left      RelationDomain
	Direction string // IN, PRECEDES, ENCLOSING, FROM, CONTAINS, FOLLOWS, BEFORE, AFTER, or user-defined
	Right     RelationDomain
}

func (b BoolNavigation) BoolType() string { return "NAVIGATION" }

// BoolEquality is variable == variable or variable != variable.
type BoolEquality struct {
	Left  EventInstance
	Right EventInstance
	NotEq bool // true for !=, false for ==
}

func (b BoolEquality) BoolType() string { return "EQUALITY" }

// BoolNumericCompare is numeric_expression comparison numeric_expression.
type BoolNumericCompare struct {
	Left     NumericExpression
	Operator string // "<", "<=", ">", ">="
	Right    NumericExpression
}

func (b BoolNumericCompare) BoolType() string { return "NUMERIC_COMPARE" }

// BoolMayOverlap is MAY_OVERLAP variable variable.
type BoolMayOverlap struct {
	Var1 EventInstance
	Var2 EventInstance
}

func (b BoolMayOverlap) BoolType() string { return "MAY_OVERLAP" }

// BoolQuantified represents FOREACH|EXISTS DISJ? variable_selection_pattern* bool_expr.
type BoolQuantified struct {
	Quantifier string // "FOREACH" or "EXISTS"
	Distinct   bool   // true if DISJ is present
	Patterns   []VarSelectionPattern
	Condition  BoolExpr
}

func (b BoolQuantified) BoolType() string { return "QUANTIFIED" }

// VarSelectionPattern represents variable ":" selection_pattern ("FROM" event_instance)?.
type VarSelectionPattern struct {
	Variable         string
	SelectionPattern *string        // optional selection pattern name
	From             *EventInstance // optional FROM clause
}

// BoolAggregate represents (OR|AND) "{" thread APPLY bool_expr "}".
type BoolAggregate struct {
	Aggregator string // "OR" or "AND"
	Thread     ThreadSelection
	Condition  BoolExpr
}

func (b BoolAggregate) BoolType() string { return "AGGREGATE" }

// NumericExpression represents arithmetic expressions for attributes and intervals.
type NumericExpression interface {
	NumericType() string
}

// NumLiteral is a numeric constant (integer or float).
type NumLiteral struct {
	Value float64
	IsInt bool // true if integer, false if float
}

func (n NumLiteral) NumericType() string { return "LITERAL" }

// NumAdd is expr + expr.
type NumAdd struct {
	Left  NumericExpression
	Right NumericExpression
}

func (n NumAdd) NumericType() string { return "ADD" }

// NumSub is expr - expr.
type NumSub struct {
	Left  NumericExpression
	Right NumericExpression
}

func (n NumSub) NumericType() string { return "SUB" }

// NumMul is expr * expr.
type NumMul struct {
	Left  NumericExpression
	Right NumericExpression
}

func (n NumMul) NumericType() string { return "MUL" }

// NumDiv is expr / expr.
type NumDiv struct {
	Left  NumericExpression
	Right NumericExpression
}

func (n NumDiv) NumericType() string { return "DIV" }

// AttrExpr represents attribute expressions (numeric or interval).
type AttrExpr interface {
	AttrType() string
}

// NumAttrExpr is a numeric expression used as an attribute value.
type NumAttrExpr struct {
	Expr NumericExpression
}

func (n NumAttrExpr) AttrType() string { return "NUM" }

// IntervalAttrExpr is an interval constructor [expr..expr].
type IntervalAttrExpr struct {
	Start NumericExpression
	End   NumericExpression
}

func (i IntervalAttrExpr) AttrType() string { return "INTERVAL" }

// IntervalConstructor represents [numeric_expression ".." numeric_expression].
type IntervalConstructor struct {
	Start NumericExpression
	End   NumericExpression
}

// StringConstructor represents a concatenation of strings and expressions for SAY clauses.
type StringConstructor []StringPart

// StringPart is one element in a string constructor (literal or expression).
type StringPart interface {
	PartType() string
}

// StringLiteral is a quoted string constant.
type StringLiteral struct {
	Value string
}

func (s StringLiteral) PartType() string { return "LITERAL" }

// StringExpr is an attribute reference in a string constructor.
type StringExpr struct {
	Attr AttrRef
}

func (s StringExpr) PartType() string { return "EXPR" }

// AttrRef represents an attribute reference: (attribute_class ".")? CNAME.
type AttrRef struct {
	Class *string // optional class like "number", "interval", "bool"
	Name  string
}

// AttrOp represents compound assignment operators: +=, -=, *=, /=, MIN=, MAX=.
type AttrOp string

const (
	AttrAssign AttrOp = ":="
	AttrAdd    AttrOp = "+="
	AttrSub    AttrOp = "-="
	AttrMul    AttrOp = "*="
	AttrDiv    AttrOp = "/="
	AttrMin    AttrOp = "MIN="
	AttrMax    AttrOp = "MAX="
)

// AggregateFunction represents SUM/TIMES/MAX/MIN aggregates.
type AggregateFunction struct {
	Function string // "SUM", "TIMES", "MAX", "MIN"
	Thread   ThreadSelection
	Expr     NumericExpression
}

// CountOperator represents "#" selection_pattern or "#{" thread }".
type CountOperator struct {
	Pattern *string          // optional selection pattern name
	Thread  *ThreadSelection // optional thread for counting
}

// TraceSegment represents a single generated trace segment.
type TraceSegment struct {
	MarkStatus   string
	Probability  float64
	Events       []EventTuple
	FollowsPairs [][2]int
	InPairs      []interface{}
	UDRs         map[string][]int
	Views        []ViewAnnotation
}

// EventTuple represents a single event in a trace segment.
type EventTuple struct {
	Name           string
	Type           string // "R" for ROOT, "A" for ATOM
	Position       int
	RootIndex      int
	CompositeIndex int // -1 if not composite
}

// ViewAnnotation represents a view annotation (SAY message, report, etc.) in a trace.
type ViewAnnotation struct {
	Type    string
	Content interface{}
}
