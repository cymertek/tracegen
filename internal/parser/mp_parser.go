// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Complete MP V4 parser implementation using AST types from grammar.go.
package parser

import (
	"fmt"
	"strconv"
	"strings"
)

// Parser is a complete recursive descent parser for the MP language (V4).
type Parser struct {
	tokens []Token
	pos    int
	errors []ParseError
}

// NewParser creates a new Parser instance.
func NewParser(tokens []Token) *Parser {
	return &Parser{
		tokens: tokens,
		pos:    0,
		errors: make([]ParseError, 0),
	}
}

// Parse tokenizes input and parses it into a SchemaNode AST.
func (p *Parser) Parse() (*SchemaNode, error) {
	if p.tokens == nil {
		return nil, fmt.Errorf("no tokens provided; use NewLexer+Tokenize first")
	}

	schema := &SchemaNode{}

	if !p.expect(TOKEN_SCHEMA) {
		return schema, p.errorf("expected 'SCHEMA' keyword")
	}

	nameToken := p.current()
	if nameToken.Type != TOKEN_CNAME {
		return nil, p.errorf("expected schema name, got %v", nameToken.Value)
	}
	schema.Name = nameToken.Value
	p.advance()

	// Parse attributes block if present
	for !p.eof() && p.current().Type == TOKEN_ATTRIBUTES {
		if err := p.parseAttributesBlock(schema); err != nil {
			return schema, err
		}
	}

	// Parse rules and coordinate blocks until EOF or next SCHEMA
	for !p.eof() && (p.current().Type != TOKEN_SCHEMA || p.peek(1).Type == TOKEN_EOF) {
		
		if p.match(TOKEN_ROOT) {
			rule, err := p.parseRule(true)
			if err != nil {
				return schema, err
			}
			schema.Rules = append(schema.Rules, *rule)
		} else if p.current().Type == TOKEN_CNAME && p.peek(1).Type == TOKEN_COLON {
			rule, err := p.parseRule(false)
			if err != nil {
				return schema, err
			}
			schema.Rules = append(schema.Rules, *rule)
		} else if p.current().Type == TOKEN_COORDINATE {
			coord, err := p.parseCoordinateBlock()
			if err != nil {
				return schema, err
			}
			schema.Coordinates = append(schema.Coordinates, coord)
		} else if p.match(TOKEN_IF) {
			// Top-level IF/THEN/FI block (e.g., Example10)
			ifBlock, err := p.parseIfBlock()
			if err != nil {
				return schema, err
			}
			schema.Coordinates = append(schema.Coordinates, &CoordinateNode{Operations: ifBlock})
		} else if p.match(TOKEN_ENSURE) {
			// Top-level ENSURE constraint (rare but possible)
			cond, err := p.parseBooleanExpression()
			if err != nil {
				return schema, err
			}
			op := CompositionOpNode{Type: "ENSURE", Condition: cond}
			schema.Coordinates = append(schema.Coordinates, &CoordinateNode{Operations: []CompositionOpNode{op}})
		} else if p.match(TOKEN_CHECK) || p.current().Value == "MARK" {
			// Top-level CHECK or MARK statement
			p.advance() // skip the keyword
			if !p.expect(TOKEN_SEMICOLON) {
				return schema, p.errorf("expected ';' after top-level CHECK/MARK")
			}
		} else if p.match(TOKEN_SHARE) {
			// Top-level SHARE clause (e.g., "Employee, Employer SHARE ALL MedicalCheck, ReadyToWork;")
			p.parseTopLevelShare(schema)
		} else {
			p.advance() // skip unknown tokens
		}
	}

	if len(p.errors) > 0 {
		return schema, fmt.Errorf("parsing completed with %d error(s): %v", len(p.errors), p.errors[0])
	}

	return schema, nil
}

// parseRule parses a rule: ROOT? CNAME ":" pattern_list (build_block)? ;
func (p *Parser) parseRule(isRoot bool) (*RuleNode, error) {
	rule := &RuleNode{IsRoot: isRoot}

	nameToken := p.current()
	if nameToken.Type != TOKEN_CNAME {
		return nil, p.errorf("expected rule name, got %v", nameToken.Value)
	}
	rule.Name = nameToken.Value
	p.advance()

	if !p.expect(TOKEN_COLON) {
		return nil, p.errorf("expected ':' after rule name")
	}

	patternList, err := p.parsePatternList(rule)
	if err != nil {
		return rule, err
	}
	rule.PatternList = patternList

	// Parse optional build block or attributes (inline ATTRIBUTES on a rule)
	for !p.eof() && (p.current().Type == TOKEN_BUILD || p.current().Type == TOKEN_ATTRIBUTES) {
		if p.match(TOKEN_BUILD) {
			buildBlock, err := p.parseBuildBlock()
			if err != nil {
				return rule, err
			}
			rule.BuildBlock = buildBlock
		} else if p.match(TOKEN_ATTRIBUTES) {
			p.parseAttributesInline(rule)
		}
	}

	p.expect(TOKEN_SEMICOLON)
	return rule, nil
}

// parsePatternList parses a pattern list: pattern (","? pattern)* until terminator.
func (p *Parser) parsePatternList(rule *RuleNode) ([]PatternUnitNode, error) {
	var patterns []PatternUnitNode

	for !p.eof() && p.current().Type != TOKEN_SEMICOLON && p.current().Type != TOKEN_RPAREN &&
		p.current().Type != TOKEN_STAR && p.current().Type != TOKEN_PLUS &&
		p.current().Type != TOKEN_RBRACE && p.current().Type != TOKEN_BUILD && p.current().Type != TOKEN_ATTRIBUTES {

		pattern, err := p.parsePatternUnit(rule)
		if err != nil {
			return patterns, err
		}
		patterns = append(patterns, pattern)

		p.match(TOKEN_COMMA) // optional comma between patterns

		if p.current().Type == TOKEN_RPAREN || p.current().Type == TOKEN_STAR || p.current().Type == TOKEN_PLUS || p.current().Type == TOKEN_RBRACE {
			break
		}
	}

	return patterns, nil
}

// parsePatternUnit parses a single pattern unit (atomic event, alternatives, iterations).
func (p *Parser) parsePatternUnit(rule *RuleNode) (PatternUnitNode, error) {
	current := p.current()

	// Handle probability annotations: <<value>> or .digits
	var prob *ProbabilityNode
	if current.Type == TOKEN_PROBABILITY_CONSTANT || current.Type == TOKEN_STRICT_PROBABILITY {
		prob = p.parseProbabilityAnnotation()
		current = p.current() // re-read after consuming probability
	}

	// Handle iteration patterns: (* event *) or (+ event +) or {* event *}
	if current.Type == TOKEN_ITERATION_START || (current.Type == TOKEN_PLUS && !p.isPlusAssign()) {
		return p.parseIteration(current, prob)
	}

	// Handle variable bindings: $var: EventName or Node$var: EventName
	if current.Type == TOKEN_VARIABLE || current.Type == TOKEN_NODE_VARIABLE || current.Type == TOKEN_NUMERIC_VARIABLE {
		varName := ""

		switch current.Type {
		case TOKEN_VARIABLE:
			varName = current.Value[1:] // strip "$"
			p.advance()
		case TOKEN_NODE_VARIABLE:
			varName = current.Value[5:] // strip "Node$"
			p.advance()
		case TOKEN_NUMERIC_VARIABLE:
			varName = current.Value[4:] // strip "Num$"
			p.advance()
		}

		if !p.expect(TOKEN_COLON) {
			return nil, p.errorf("expected ':' after variable binding")
		}

		eventName := p.current().Value
		if eventName == "" || (!isLetter(eventName[0]) && eventName[0] != '_') {
			return nil, p.errorf("expected event name after colon")
		}

		eventNode := &AtomicEventNode{
			Name:        eventName,
			Variable:    &varName,
			NodeVar:     nil,
			Probability: prob,
		}

		p.advance() // skip event name
		return eventNode, nil
	}

	// Handle alternatives: ( pattern | pattern )
	if current.Type == TOKEN_LPAREN {
		p.advance() // skip '('
		var alternatives []AlternativeNode

		for !p.eof() && p.current().Type != TOKEN_RPAREN {
			altPatterns := make([]PatternUnitNode, 0)
			for !p.eof() && p.current().Type != TOKEN_BAR && p.current().Type != TOKEN_RPAREN {
				pattern, err := p.parsePatternUnit(rule)
				if err != nil {
					return nil, err
				}
				altPatterns = append(altPatterns, pattern)
			}

			alternatives = append(alternatives, AlternativeNode{
				PatternList: altPatterns,
			})

			if !p.match(TOKEN_BAR) {
				break
			}
		}

		p.expect(TOKEN_RPAREN)
		return &AltGroupNode{Alternatives: alternatives}, nil
	}

	// Handle optional patterns: [ pattern ]
	if current.Type == TOKEN_LBRACKET {
		p.advance() // skip '['

		var optPatterns []PatternUnitNode
		for !p.eof() && p.current().Type != TOKEN_RBRACKET {
			pattern, err := p.parsePatternUnit(rule)
			if err != nil {
				return nil, err
			}
			optPatterns = append(optPatterns, pattern)
			p.match(TOKEN_COMMA)
		}

		p.expect(TOKEN_RBRACKET)
		return &OptionalPatternNode{Probability: prob, PatternList: optPatterns}, nil
	}

	// Handle atomic events (bare event names)
	if current.Type == TOKEN_CNAME || (len(current.Value) > 0 && isLetter(current.Value[0])) {
		eventName := current.Value
		p.advance() // skip event name

		return &AtomicEventNode{
			Name:        eventName,
			Variable:    nil,
			NodeVar:     nil,
			Probability: prob,
		}, nil
	}

	// Handle set patterns: {+ pattern +} or {* pattern *} or { pattern }
	if current.Type == TOKEN_LBRACE {
		p.advance() // skip '{'

		var items []PatternUnitNode
		isPlusSet := false

		// Check for delimited set syntax: {+ ... +} or {* ... *}
		if p.match(TOKEN_PLUS) || p.match(TOKEN_STAR) {
			isPlusSet = p.prev().Type == TOKEN_PLUS
			for !p.eof() && p.current().Type != TOKEN_RBRACE && p.current().Type != TOKEN_PLUS && p.current().Type != TOKEN_STAR {
				item, err := p.parsePatternUnit(rule)
				if err != nil {
					return nil, err
				}
				items = append(items, item)
				p.match(TOKEN_COMMA)
			}
			// If we see PLUS or STAR here, it's the closing delimiter for set_it_plus
			if p.current().Type == TOKEN_PLUS || p.current().Type == TOKEN_STAR {
				p.advance() // skip closing + or *
			}
		} else {
			// Undelimited set pattern: { element1 element2 ... }
			for !p.eof() && p.current().Type != TOKEN_RBRACE {
				item, err := p.parsePatternUnit(rule)
				if err != nil {
					return nil, err
				}
				items = append(items, item)
				p.match(TOKEN_COMMA) // optional comma between elements
			}
		}

		p.expect(TOKEN_RBRACE)

		if isPlusSet {
			var firstItem PatternUnitNode
			if len(items) > 0 {
				firstItem = items[0]
			}
			return &ItPlusPatternNode{Item: firstItem, PatternList: items}, nil
		}
		return &SetPatternNode{Bounded: false, Items: items}, nil
	}

	return nil, p.errorf("unexpected token in pattern: %v", current.Value)
}

// parseIteration handles (* event *), (+ event +), {* event *} patterns.
func (p *Parser) parseIteration(current Token, _ *ProbabilityNode) (PatternUnitNode, error) {
	isStar := current.Type == TOKEN_ITERATION_START || current.Type == TOKEN_STAR
	isPlus := current.Type == TOKEN_PLUS

	if isStar {
		// Advance past the iteration start token (lexer already consumed '(*')
		p.advance()

		// Check for bounded iteration: (* <lower> .. <upper> pattern *)
		var scope *IterationScopeNode
		if p.current().Type == TOKEN_INTERVAL_START {
			scope = p.parseBoundedScope()
		}

		var items []PatternUnitNode
		for !p.eof() && p.current().Type != TOKEN_ITERATION_END && p.current().Type != TOKEN_RPAREN && p.current().Type != TOKEN_STAR {
			item, err := p.parsePatternUnit(nil)
			if err != nil {
				return nil, err
			}
			items = append(items, item)
			p.match(TOKEN_COMMA)
		}

		for !p.eof() && p.current().Type == TOKEN_COMMENT {
			p.advance()
		}
		if p.current().Type == TOKEN_ITERATION_END {
			p.advance() // consumed *)
		} else if p.current().Type == TOKEN_STAR {
			p.advance()
			p.match(TOKEN_RPAREN)
		}

		if scope != nil {
			return &ItPatternNode{Scope: scope, PatternList: items}, nil
		}
		return &ListPatternNode{Bounded: false, Items: items}, nil
	}

	if isPlus {
		p.advance() // skip +

		// Check for bounded iteration: + <lower> .. <upper> pattern +
		var scope *IterationScopeNode
		if p.current().Type == TOKEN_INTERVAL_START {
			scope = p.parseBoundedScope()
		}

		item, err := p.parsePatternUnit(nil)
		if err != nil {
			return nil, err
		}

		patterns := []PatternUnitNode{item}
		for !p.eof() && p.current().Type != TOKEN_PLUS {
			nextItem, err := p.parsePatternUnit(nil)
			if err != nil {
				return nil, err
			}
			patterns = append(patterns, nextItem)
			p.match(TOKEN_COMMA)
		}

		p.advance() // skip closing +

		if scope != nil {
			return &ItPlusPatternNode{Scope: scope, Item: item, PatternList: patterns}, nil
		}
		return &ItPlusPatternNode{Item: item, PatternList: patterns}, nil
	}

	return nil, p.errorf("expected iteration pattern, got %v", current.Value)
}

// parseBoundedScope parses a bounded iteration scope: <lower> .. <upper>.
// Returns an IterationScopeNode with Min and Max values.
func (p *Parser) parseBoundedScope() *IterationScopeNode {
	scope := &IterationScopeNode{Min: 0, Max: -1} // default to unbounded

	// Parse lower bound expression
	lowerExpr := p.parseIntervalExpression()
	if lowerExpr != nil {
		if lit, ok := lowerExpr.(*NumLitExpr); ok {
			scope.Min = int(lit.Value)
		} else if _, ok := lowerExpr.(*VarRefExpr); ok {
			// Store variable reference for later evaluation
			scope.Min = -1 // indicate unbounded/variable
		}
	}

	// Consume .. operator
	if p.current().Type == TOKEN_DOT && p.peek(1).Type == TOKEN_DOT {
		p.advance() // consume first .
		p.advance() // consume second .
	} else if p.current().Type == TOKEN_INTERVAL_END {
		// No .. found, treat as single bound
		return scope
	}

	// Parse upper bound expression
	if !p.eof() && p.current().Type != TOKEN_INTERVAL_END {
		upperExpr := p.parseIntervalExpression()
		if upperExpr != nil {
			if lit, ok := upperExpr.(*NumLitExpr); ok {
				scope.Max = int(lit.Value)
			} else if _, ok := upperExpr.(*VarRefExpr); ok {
				scope.Max = -1 // indicate unbounded/variable
			}
		}
	}

	// Consume closing >
	if p.current().Type == TOKEN_INTERVAL_END {
		p.advance()
	}

	return scope
}

// parseIntervalExpression parses a simple arithmetic expression for interval bounds.
func (p *Parser) parseIntervalExpression() ASTNode {
	var left ASTNode = &NumLitExpr{Value: 0} // default to 0 if no expression found

	if p.current().Type == TOKEN_NUMBER_CONSTANT || p.current().Type == TOKEN_INTEGER_CONSTANT {
		value, err := strconv.ParseFloat(p.current().Value, 64)
		if err != nil {
			return left
		}
		left = &NumLitExpr{Value: value}
		p.advance()
	} else if p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_NODE_VARIABLE {
		varName := ""
		if p.current().Type == TOKEN_VARIABLE {
			varName = p.current().Value[1:] // strip $
		} else if p.current().Type == TOKEN_NODE_VARIABLE {
			varName = p.current().Value[5:] // strip Node$
		}
		left = &VarRefExpr{Value: varName}
		p.advance()
	}

	return left
}

// isPlusAssign checks if the current '+' is part of a '+=' compound assignment.
func (p *Parser) isPlusAssign() bool {
	if p.current().Type == TOKEN_PLUS && p.peek(1).Type == TOKEN_ASSIGN {
		return true
	}
	return false
}

// parseProbabilityAnnotation handles <<value>> or .digits probability annotations.
func (p *Parser) parseProbabilityAnnotation() *ProbabilityNode {
	current := p.current()
	var value = 1.0

	if current.Type == TOKEN_PROBABILITY_CONSTANT || current.Type == TOKEN_STRICT_PROBABILITY {
		valueStr := strings.TrimPrefix(current.Value, "\"")
		valueStr = strings.TrimSuffix(valueStr, "\"")
		v, err := strconv.ParseFloat(valueStr, 64)
		if err == nil && v >= 0 && v <= 1 {
			value = v
		}
		p.advance()
	}

	return &ProbabilityNode{Value: value}
}

// parseBuildBlock parses a BUILD block with composition operations.
func (p *Parser) parseBuildBlock() (*BuildBlockNode, error) {
	build := &BuildBlockNode{}

	if !p.expect(TOKEN_LBRACE) {
		return build, p.errorf("expected '{' after BUILD")
	}

	for !p.eof() && p.current().Type != TOKEN_RBRACE {
			
		// Handle nested COORDINATE blocks within BUILD
		if p.match(TOKEN_COORDINATE) {
			nestedCoord, err := p.parseCoordinateBlock()
			if err != nil {
				return build, fmt.Errorf("parsing nested coordinate in BUILD: %w", err)
			}
			build.NestedCoordinates = append(build.NestedCoordinates, nestedCoord)
			continue
		}
		
		op := p.currentCompositionOp()
		if op != nil {
			build.Operations = append(build.Operations, *op)
		} else if p.match(TOKEN_ATTRIBUTES) {
			p.parseAttributesInline(&RuleNode{BuildBlock: build})
		} else {
					p.advance() // skip unknown token in BUILD block
		}
	}

	if !p.match(TOKEN_RBRACE) {
		return build, p.errorf("expected '}' to close BUILD block")
	}

	return build, nil
}

// parseAttributesInline parses inline ATTRIBUTES on a rule (not in BUILD).
func (p *Parser) parseAttributesInline(rule *RuleNode) {
	p.advance() // skip ATTRIBUTES keyword

	if p.current().Type != TOKEN_LBRACE {
		return
	}
	p.advance() // skip '{'

	for !p.eof() && p.current().Type != TOKEN_RBRACE {
		nameToken := p.current()
		if nameToken.Type == TOKEN_CNAME {
			varName := nameToken.Value
			attrType := AttributeTypeNumber

			p.advance()

			// Check if it's a type keyword (NUMBER, INTERVAL, BOOLEAN)
			if p.current().Value == "NUMBER" || p.current().Value == "INTERVAL" || p.current().Value == "BOOLEAN" {
				switch p.current().Value {
				case "INTERVAL":
					attrType = AttributeTypeInterval
				case "BOOLEAN":
					attrType = AttributeTypeBoolean
				}
				p.advance()

				if p.match(TOKEN_ASSIGN) || p.current().Value == "=" {
					p.advance()
				}

				varName = p.current().Value
				p.advance()
			} else if p.match(TOKEN_ASSIGN) || p.current().Value == ":" {
				p.advance()
			}

			rule.Attributes = append(rule.Attributes, AttributeDeclarationNode{
				Name: varName,
				Type: attrType,
			})
		} else {
			p.advance()
		}

		p.match(TOKEN_COMMA)
	}

	p.expect(TOKEN_RBRACE)
}

// parseCoordinateBlock parses a COORDINATE block with threads and DO...OD operations.
func (p *Parser) parseCoordinateBlock() (*CoordinateNode, error) {
	coord := &CoordinateNode{}

	// Optionally consume COORDINATE keyword - caller may have already matched it
	// (e.g., when called from parseBuildBlock after p.match(TOKEN_COORDINATE))
	p.match(TOKEN_COORDINATE)

	// Parse optional modifiers like <REVERSE> that can appear after COORDINATE
	for !p.eof() && p.current().Type == TOKEN_LESS {
		p.advance() // skip '<'
		if p.current().Value == "REVERSE" || (p.current().Type == TOKEN_CNAME) {
			modifier := p.current().Value
			coord.Modifiers = append(coord.Modifiers, modifier)
			p.advance() // skip modifier name
			if !p.match(TOKEN_GREATER) {
				return coord, p.errorf("expected '>' after modifier")
			}
		} else {
			p.advance() // skip unknown token after '<'
		}
	}

	// Parse thread declarations: $x: send FROM Sender, ...
	var threads []ThreadSelectionNode
	for !p.eof() && (p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_NODE_VARIABLE) {
		thread := ThreadSelectionNode{}

		if p.current().Type == TOKEN_VARIABLE {
			varName := p.current().Value[1:] // strip "$"
			thread.Variable = &varName
			p.advance()
		} else if p.current().Type == TOKEN_NODE_VARIABLE {
			varName := p.current().Value[5:] // strip "Node$"
			thread.NodeVar = &varName
			p.advance()
		}

		if !p.expect(TOKEN_COLON) {
			return coord, p.errorf("expected ':' after thread variable")
		}

		eventName := p.current().Value
		thread.EventName = eventName
		p.advance()

		// Parse optional FROM clause
		if p.match(TOKEN_FROM) {
			fromToken := p.current()
			if fromToken.Type == TOKEN_CNAME {
				thread.From = &EventInstanceNode{Name: fromToken.Value}
				p.advance()
			}
		}

		threads = append(threads, thread)
		p.match(TOKEN_COMMA)
	}

	coord.Threads = threads

	// Skip optional SUCH/THAT condition between threads and DO (for nested coords like Example04)
	for !p.eof() && (p.current().Value == "SUCH" || p.current().Value == "THAT") {
		p.advance() // skip SUCH or THAT keyword
	}

	// Parse DO ... OD block (may contain nested coordinates)
	if p.match(TOKEN_DO) {
		for !p.eof() {
			// Check for composition operations first
			op := p.currentCompositionOp()
			if op != nil {
				coord.Operations = append(coord.Operations, *op)
				continue
			}

			// Check for nested COORDINATE inside this DO...OD
			if p.current().Type == TOKEN_COORDINATE {
				nestedCoord, err := p.parseCoordinateBlock()
				if err != nil {
					return coord, fmt.Errorf("parsing nested coordinate: %w", err)
				}
				coord.NestedCoords = append(coord.NestedCoords, nestedCoord)
				continue
			}

			// Check for closing OD at this level
			if p.match(TOKEN_OD) {
				break // consumed the matching OD - done with DO...OD
			}

			// Skip any other tokens (SUCH THAT, IF/THEN/FI, control flow keywords)
			p.advance()
		}
		// After DO...OD, skip optional semicolons between OD and next coord/thread
		for p.match(TOKEN_SEMICOLON) {
		}
	}

	return coord, nil
}

// isSkipToken checks if a token should be skipped in DO...OD blocks
// (such as IF, THEN, FI, NOT, OR, AND, EXISTS, SUCH, THAT, etc.)
func isSkipToken(t Token) bool {
	val := strings.ToUpper(t.Value)
	switch t.Type {
	case TOKEN_IF, TOKEN_THEN, TOKEN_ELSE, TOKEN_FI:
		return true
	case TOKEN_NOT, TOKEN_AND, TOKEN_OR:
		return true
	default:
		switch val {
		case "SUCH", "THAT", "EXISTS":
			return true
		}
		return false
	}
}

// currentCompositionOp returns the next composition operation or nil if none.
func (p *Parser) currentCompositionOp() *CompositionOpNode {
	current := p.current()

	if current.Type == TOKEN_ADD {
		p.advance() // skip ADD

		op := &CompositionOpNode{Type: "ADD"}

		leftVar := ""
		rightVar := ""

		if p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_NODE_VARIABLE {
			if p.current().Type == TOKEN_VARIABLE {
				leftVar = p.current().Value[1:]
			} else if p.current().Type == TOKEN_NODE_VARIABLE {
				leftVar = p.current().Value[5:]
			}
			p.advance()
		}

		relToken := p.current()
		if relToken.Type == TOKEN_CNAME || isRelationName(relToken.Value) {
			op.RelationName = relToken.Value
			p.advance()
		}

		if p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_NODE_VARIABLE {
			if p.current().Type == TOKEN_VARIABLE {
				rightVar = p.current().Value[1:]
			} else if p.current().Type == TOKEN_NODE_VARIABLE {
				rightVar = p.current().Value[5:]
			}
			p.advance()
		}

		op.LeftVariable = leftVar
		op.RightVariable = rightVar
		return op
	}

	if current.Type == TOKEN_ENSURE {
		p.advance() // skip ENSURE

		expr, err := p.parseBooleanExpression()
		if err != nil {
			return nil
		}

		return &CompositionOpNode{
			Type:       "ENSURE",
			Expression: expr,
		}
	}

	if current.Type == TOKEN_IF {
			p.advance() // skip IF

		expr, err := p.parseBooleanExpression()
		if err != nil {
					return nil
		}

		
		op := &CompositionOpNode{
			Type:      "IF_THEN_ELSE",
			Condition: expr,
		}

		if !p.expect(TOKEN_THEN) {
					return op
		}

		var thenOps []CompositionOpNode
		for !p.eof() && (p.current().Type != TOKEN_ELSE && p.current().Type != TOKEN_FI) {
					subOp := p.currentCompositionOp()
			if subOp != nil {
				thenOps = append(thenOps, *subOp)
			} else {
							p.advance()
			}
		}
		op.ThenBranch = thenOps

		if p.match(TOKEN_ELSE) {
			var elseOps []CompositionOpNode
			for !p.eof() && p.current().Type != TOKEN_FI {
				subOp := p.currentCompositionOp()
				if subOp != nil {
					elseOps = append(elseOps, *subOp)
				} else {
					p.advance()
				}
			}
			op.ElseBranch = elseOps
		}

		if !p.match(TOKEN_FI) {
			return nil
		}
		p.match(TOKEN_SEMICOLON)
		return op
	}

	if current.Type == TOKEN_FOR {
		p.advance() // skip FOR

		variable := ""
		if p.current().Type == TOKEN_VARIABLE {
			variable = p.current().Value[1:]
			p.advance()
		}

		op := &CompositionOpNode{
			Type:         "FOR_LOOP",
			LoopVariable: variable,
		}

		if !p.expect(TOKEN_FROM) {
			return op
		}

		startExpr, err := p.parseNumericExpression()
		if err == nil {
			op.LoopStart = startExpr
		}

		if !p.expect(TOKEN_TO) {
			return op
		}

		endExpr, err := p.parseNumericExpression()
		if err == nil {
			op.LoopEnd = endExpr
		}

		if p.match(TOKEN_STEP) {
			stepExpr, err := p.parseNumericExpression()
			if err == nil {
				op.LoopStep = stepExpr
			}
		}

		if !p.expect(TOKEN_DO) {
			return op
		}

		var bodyOps []CompositionOpNode
		for !p.eof() && !p.match(TOKEN_OD) {
			subOp := p.currentCompositionOp()
			if subOp != nil {
				bodyOps = append(bodyOps, *subOp)
			} else {
				p.advance()
			}
		}
		op.LoopBody = bodyOps

		return op
	}

	if current.Value == "MAP" {
		p.advance() // skip MAP

		variable := ""
		if p.current().Type == TOKEN_VARIABLE {
			variable = p.current().Value[1:]
			p.advance()
		}

		op := &CompositionOpNode{
			Type:        "MAP",
			MapVariable: variable,
		}

		if !p.expect(TOKEN_FROM) {
			return op
		}

		collectionExpr, err := p.parseExpression()
		if err == nil {
			op.Collection = collectionExpr
		}

		if !p.expect(TOKEN_DO) {
			return op
		}

		var bodyOps []CompositionOpNode
		for !p.eof() && !p.match(TOKEN_OD) {
			subOp := p.currentCompositionOp()
			if subOp != nil {
				bodyOps = append(bodyOps, *subOp)
			} else {
				p.advance()
			}
		}
		op.MapBody = bodyOps

		return op
	}

	if current.Type == TOKEN_SAY {
		p.advance() // skip SAY

		message := ""
		if p.current().Type == TOKEN_LPAREN {
			// Parenthesized expression: SAY(expr)
			p.advance() // skip '('
			message = p.parseSayExpression()
			p.expect(TOKEN_RPAREN)
		} else if p.current().Type == TOKEN_STRING_CONSTANT || p.current().Type == TOKEN_CNAME {
			message = p.current().Value
			p.advance()
		}

		return &CompositionOpNode{
			Type:    "SAY",
			Message: message,
		}
	}

	if current.Type == TOKEN_CHECK {
		p.advance() // skip CHECK

		expr, err := p.parseBooleanExpression()
		if err != nil {
			return nil
		}

		return &CompositionOpNode{
			Type:       "CHECK",
			Expression: expr,
		}
	}

	if current.Type == TOKEN_ONFAIL {
		p.advance() // skip ONFAIL

		action := p.currentCompositionOp()
		if action != nil {
			return &CompositionOpNode{
				Type:          "ONFAIL",
				FailureAction: action,
			}
		}
		return nil
	}

	if current.Type == TOKEN_SET {
		p.advance() // skip SET

		variable := ""
		if p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_NODE_VARIABLE {
			if p.current().Type == TOKEN_VARIABLE {
				variable = p.current().Value[1:]
			} else if p.current().Type == TOKEN_NODE_VARIABLE {
				variable = p.current().Value[5:]
			}
			p.advance()
		}

		if !p.expect(TOKEN_TO) {
			return nil
		}

		expr, err := p.parseExpression()
		if err != nil {
			return nil
		}

		return &CompositionOpNode{
			Type:       "SET",
			Variable:   variable,
			Expression: expr,
		}
	}

	return nil
}

// parseBooleanExpression parses a boolean expression for ENSURE/IF/CHECK clauses.
func (p *Parser) parseBooleanExpression() (BoolExprNode, error) {
	// Handle quantifiers: FOREACH|EXISTS DISJ? pattern* bool_expr
	if p.current().Value == "FOREACH" || p.current().Value == "EXISTS" {
		return p.parseQuantifiedExpression()
	}


	left, err := p.parseComparisonExpression()
	if err != nil {
		return left, err
	}

	for !p.eof() && (p.current().Type == TOKEN_AND || p.current().Type == TOKEN_OR) {
		var right BoolExprNode
		right, err = p.parseComparisonExpression()
		if err != nil {
			return left, err
		}

		if p.match(TOKEN_AND) {
			left = &BoolAndNode{Left: left, Right: right}
		} else if p.match(TOKEN_OR) {
			left = &BoolOrNode{Left: left, Right: right}
		}
	}

	return left, nil
}

// parseQuantifiedExpression handles FOREACH/EXISTS quantifiers.
func (p *Parser) parseQuantifiedExpression() (*BoolQuantifiedNode, error) {
	quantifier := p.current().Value // "FOREACH" or "EXISTS"
	p.advance()

	node := &BoolQuantifiedNode{
		Quantifier: quantifier,
	}

	// Check for DISJ (distinct) keyword
	if p.match(TOKEN_CNAME) && p.prev().Value == "DISJ" {
		node.Distinct = true
	}

	// Parse variable selection patterns: $var: event FROM source, ...
	for !p.eof() && p.current().Type == TOKEN_VARIABLE {
		varSel := VarSelectionPatternNode{}

		varName := p.current().Value[1:] // strip '$'
		p.advance()

		if !p.expect(TOKEN_COLON) {
			return node, p.errorf("expected ':' after variable in quantifier")
		}

		eventName := p.current().Value
		if eventName == "" || (!isLetter(eventName[0]) && eventName[0] != '_') {
			return node, p.errorf("expected event name after ':'")
		}
		p.advance()

		varSel.Variable = varName

		// Parse optional FROM clause
		if p.match(TOKEN_FROM) {
			fromToken := p.current()
			if fromToken.Type == TOKEN_CNAME {
				varSel.From = &EventInstanceNode{Name: fromToken.Value}
				p.advance()
			}
		}

		node.Patterns = append(node.Patterns, varSel)
		p.match(TOKEN_COMMA) // optional comma between patterns
	}

	// Parse the condition expression (may be parenthesized)
	if p.current().Type == TOKEN_LPAREN {
		p.advance() // skip '('
		cond, err := p.parseBooleanExpression()
		if err != nil {
			return node, err
		}
		node.Condition = cond
		p.expect(TOKEN_RPAREN)
	} else if isLetter(p.current().Value[0]) || p.current().Type == TOKEN_VARIABLE || p.current().Type == TOKEN_HASH {
		cond, err := p.parseBooleanExpression()
		if err != nil {
			return node, err
		}
		node.Condition = cond
	}

	return node, nil
}

// parseComparisonExpression parses a comparison expression (==, !=, <, <=, >, >=)
// or navigation chain (event BEFORE/IN/PRECEDES/AFTER/etc event).
func (p *Parser) parseComparisonExpression() (BoolExprNode, error) {
	left, err := p.parseNumericExpression()
	if err != nil {
		return nil, err
	}

	current := p.current()

	// Check for comparison operators first: ==, !=, <, <=, >, >=
	switch current.Type {
	case TOKEN_EQUALS, TOKEN_NOT_EQUAL, TOKEN_LESS, TOKEN_LESS_EQ, TOKEN_GREATER, TOKEN_GREATER_EQ:
			p.advance() // consume the operator
		right, err := p.parseNumericExpression()
		if err != nil {
			return nil, err
		}

		leftNode := toNumExpr(left)
		rightNode := toNumExpr(right)
	
		return &BoolNumericCompareNode{
			Left:     leftNode,
			Operator: comparisonOpName(current.Type),
			Right:    rightNode,
		}, nil
	}

	// Check for navigation operators: event BEFORE/IN/PRECEDES/AFTER/etc event
	if isNavigationOperator(current) {
		direction := current.Value
		p.advance() // consume the navigation operator

		right, err := p.parseNumericExpression()
		if err != nil {
			return nil, err
		}

		leftDomain := toRelationDomain(left)
		rightDomain := toRelationDomain(right)

		if leftDomain == nil || rightDomain == nil {
			return nil, p.errorf("invalid navigation expression: %v %s %v", left, direction, right)
		}

		result := &BoolNavigationNode{
			Left:      *leftDomain,
			Direction: direction,
			Right:     *rightDomain,
		}

		// After parsing a navigation chain (e.g., #pop BEFORE $x), check if
		// the next token is a comparison operator (<, >, <=, >=, ==, !=). If so, try to
		// parse what follows as a boolean expression. But first verify that
		// what comes after the comparison operator can actually form a valid
		// left operand — otherwise this is one big navigation chain treated
		// as a single boolean unit (e.g., #pop BEFORE $x < #push BEFORE $x).
		if !p.eof() && isComparisonOperator(p.current()) {
			savedPos := p.pos
			p.advance() // consume the comparison operator

			testExpr, testErr := p.parseBooleanExpression()
			if testErr != nil || testExpr == nil {
				// Can't parse a valid expression after comparison — the whole thing
				// (navigation + comparison) is one boolean expression.
				p.pos = savedPos
				return result, nil
			}

			// Valid expression found. Build: navigation_chain COMP parsed_expr
			rightNode := toNumExpr(testExpr)
			if rightNode == nil {
				rightNode = &NumExprNode{Left: testExpr}
			}

			return &BoolNumericCompareNode{
				Left:     toNumExpr(left),
				Operator: p.prev().Value,
				Right:    rightNode,
			}, nil
		}

		return result, nil
	}

	// No operator - return as-is (numeric expression used as bool)
	if be, ok := toBoolExpr(left); ok {
		return be, nil
	}
	return left.(BoolExprNode), nil
}

// toNumExpr converts an ASTNode to *NumExprNode if needed.
func toNumExpr(node ASTNode) *NumExprNode {
	if n, ok := node.(*NumExprNode); ok {
		return n
	}
	return &NumExprNode{Left: node} // wrap single value
}

// toBoolExpr converts an ASTNode to BoolExprNode if it implements the interface.
func toBoolExpr(node ASTNode) (BoolExprNode, bool) {
	if be, ok := node.(BoolExprNode); ok {
		return be, true
	}
	return nil, false
}

// isNavigationOperator checks if the current token is a navigation direction.
func isNavigationOperator(t Token) bool {
	switch t.Value {
	case "BEFORE", "AFTER", "IN", "PRECEDES", "ENCLOSING", "CONTAINS",
		"FOLLOWS", "LEFT_OF", "RIGHT_OF":
		return true
	default:
		return false
	}
}

// isScopeFilter checks if the current token is TOKEN_FROM, indicating a scope filter.
func (p *Parser) isScopeFilter() bool {
	return p.current().Type == TOKEN_FROM
}

// isComparisonOperator checks if a token type represents a comparison operator.
func isComparisonOperator(t Token) bool {
	switch t.Type {
	case TOKEN_EQUALS, TOKEN_NOT_EQUAL, TOKEN_LESS, TOKEN_LESS_EQ, TOKEN_GREATER, TOKEN_GREATER_EQ:
		return true
	default:
		return false
	}
}

// toRelationDomain converts an ASTNode to a RelationDomain if possible.
func toRelationDomain(node ASTNode) *RelationDomainNode {
	switch n := node.(type) {
	case *CountExpr:
		return &RelationDomainNode{Event: &EventInstanceNode{Name: n.EventName}}
	case *VarRefExpr:
		return &RelationDomainNode{Event: &EventInstanceNode{Variable: &n.Value}}
	case *NumLitExpr:
		// Numeric literals don't have relation domain meaning, return nil
		return nil
	default:
		// Try to extract name from other nodes
		if s, ok := node.(fmt.Stringer); ok {
			return &RelationDomainNode{Event: &EventInstanceNode{Name: s.String()}}
		}
		return nil
	}
}

// comparisonOpName returns the operator string for a token type.
func comparisonOpName(t TokenType) string {
	switch t {
	case TOKEN_EQUALS:
		return "=="
	case TOKEN_NOT_EQUAL:
		return "!="
	case TOKEN_LESS:
		return "<"
	case TOKEN_LESS_EQ:
		return "<="
	case TOKEN_GREATER:
		return ">"
	case TOKEN_GREATER_EQ:
		return ">="
	default:
		return ""
	}
}

// parseNumericExpression parses a numeric expression with arithmetic operators.
func (p *Parser) parseNumericExpression() (ASTNode, error) {
	left, err := p.parsePrimaryExpression()
	if err != nil {
		return nil, err
	}

	for !p.eof() && (p.current().Type == TOKEN_PLUS || p.current().Type == TOKEN_MINUS) {
		operator := ""
		if p.match(TOKEN_PLUS) {
			operator = "+"
		} else if p.match(TOKEN_MINUS) {
			operator = "-"
		}

		right, err := p.parsePrimaryExpression()
		if err != nil {
			return nil, err
		}

		left = &NumExprNode{Left: left, Operator: operator, Right: right}
	}

	return left, nil
}

// parsePrimaryExpression parses a primary expression (number, variable, or parenthesized).
func (p *Parser) parsePrimaryExpression() (ASTNode, error) {
	current := p.current()

	if current.Type == TOKEN_LPAREN {
		p.advance() // skip '('
		expr, err := p.parseNumericExpression()
		if err != nil {
			return nil, err
		}
		p.expect(TOKEN_RPAREN)
		return expr, nil
	}

	// Handle count operator: #event_name [FROM source] (must be followed by an operator)
	if current.Type == TOKEN_HASH {
		p.advance() // skip '#'
		if p.current().Type == TOKEN_CNAME {
			eventName := p.current().Value
			p.advance()

			expr := &CountExpr{EventName: eventName}
					// Check for optional scope filter: FROM source
			if p.isScopeFilter() {
				p.advance() // consume FROM
				fromToken := p.current()
				if fromToken.Type == TOKEN_CNAME {
					expr.Scope = &EventInstanceNode{Name: fromToken.Value}
									p.advance()
				}
			}

			return expr, nil
		}
		return nil, p.errorf("expected event name after #")
	}

	if current.Type == TOKEN_VARIABLE || current.Type == TOKEN_NODE_VARIABLE || current.Type == TOKEN_NUMERIC_VARIABLE {
		varName := ""
		switch current.Type {
		case TOKEN_VARIABLE:
			varName = current.Value[1:]
		case TOKEN_NODE_VARIABLE:
			varName = current.Value[5:]
		case TOKEN_NUMERIC_VARIABLE:
			varName = current.Value[4:]
		}
		p.advance()

		expr := &VarRefExpr{Value: varName}
		// Check for optional scope filter: FROM source
		if p.isScopeFilter() {
			p.advance() // consume FROM
			fromToken := p.current()
			if fromToken.Type == TOKEN_CNAME {
				expr.Scope = &EventInstanceNode{Name: fromToken.Value}
				p.advance()
			}
		}
		return expr, nil
	}

	if current.Type == TOKEN_NUMBER_CONSTANT || current.Type == TOKEN_INTEGER_CONSTANT || current.Type == TOKEN_FLOAT_CONSTANT {
		value, err := strconv.ParseFloat(current.Value, 64)
		if err != nil {
			return nil, p.errorf("invalid number: %v", current.Value)
		}
		p.advance()

		return &NumLitExpr{Value: value}, nil
	}

	if current.Type == TOKEN_TRUE || current.Type == TOKEN_FALSE {
		value := false
		if p.match(TOKEN_TRUE) {
			value = true
		} else if p.match(TOKEN_FALSE) {
			value = false
		}

		return &BoolLitExpr{Value: value}, nil
	}

	return nil, p.errorf("unexpected token in expression: %v", current.Value)
}

// parseExpression parses a general expression (for MAP FROM clauses).
func (p *Parser) parseExpression() (*NumExprNode, error) {
	expr := &NumExprNode{}

	left, err := p.parsePrimaryExpression()
	if err != nil {
		return expr, err
	}
	expr.Left = left

	for !p.eof() && (p.current().Type == TOKEN_PLUS || p.current().Type == TOKEN_MINUS) {
		operator := ""
		if p.match(TOKEN_PLUS) {
			operator = "+"
		} else if p.match(TOKEN_MINUS) {
			operator = "-"
		}

		right, err := p.parsePrimaryExpression()
		if err != nil {
			return expr, err
		}

		expr.Right = right
		expr.Operator = operator
	}

	return expr, nil
}

// parseSayExpression parses a SAY expression which can be:
// - A string constant "..."
// - An attribute reference (e.g., #send)
// - An arithmetic expression (#send - #receive)
func (p *Parser) parseSayExpression() string {
	if p.eof() {
		return ""
	}

	var sb strings.Builder

	for !p.eof() && p.current().Type != TOKEN_RPAREN && p.current().Type != TOKEN_SEMICOLON {
		current := p.current()

		switch current.Type {
		case TOKEN_STRING_CONSTANT, TOKEN_CNAME, TOKEN_VARIABLE:
			sb.WriteString(current.Value)
			p.advance()
		case TOKEN_MINUS, TOKEN_PLUS:
			sb.WriteString(current.Value)
			p.advance()
		default:
			// Skip other tokens (operators, parens, etc.)
			p.advance()
		}

		if !p.eof() && p.current().Type != TOKEN_RPAREN && p.current().Type != TOKEN_SEMICOLON {
			sb.WriteString(" ") // Add space between elements
		}
	}

	return strings.TrimSpace(sb.String())
}

// parseAttributesBlock parses an ATTRIBUTES block on a schema.
func (p *Parser) parseAttributesBlock(schema *SchemaNode) error {
	p.advance() // skip ATTRIBUTES keyword

	if p.current().Type != TOKEN_LBRACE {
		return p.errorf("expected '{' after ATTRIBUTES")
	}
	p.advance() // skip '{'

	for !p.eof() && p.current().Type != TOKEN_RBRACE {
		nameToken := p.current()
		if nameToken.Type == TOKEN_CNAME {
			varName := nameToken.Value
			attrType := AttributeTypeNumber

			p.advance() // skip attribute name

			// Check if it's a type keyword (NUMBER, INTERVAL, BOOLEAN)
			if p.current().Value == "NUMBER" || p.current().Value == "INTERVAL" || p.current().Value == "BOOLEAN" {
				switch p.current().Value {
				case "INTERVAL":
					attrType = AttributeTypeInterval
				case "BOOLEAN":
					attrType = AttributeTypeBoolean
				}
				p.advance() // skip type keyword

				if p.match(TOKEN_ASSIGN) || p.current().Value == "=" {
					p.advance() // skip : or =
				}

				varName = p.current().Value
				p.advance()
			} else if p.match(TOKEN_ASSIGN) || p.current().Value == ":" {
				p.advance() // skip : or =
			}

			attr := AttributeDeclarationNode{
				Name: varName,
				Type: attrType,
			}

			// Handle navigation operators: ^name, ~name
			for !p.eof() && (p.current().Type == TOKEN_CARET || p.current().Type == TOKEN_TILDE) {
				op := ""
				if p.match(TOKEN_CARET) {
					op = "up"
				} else if p.match(TOKEN_TILDE) {
					op = "down"
				}

				nextVarName := p.current().Value
				p.advance()

				attr.Name += "." + op + nextVarName
			}

			schema.Attributes = append(schema.Attributes, attr)
		} else {
			p.advance() // skip non-identifier
		}

		p.match(TOKEN_COMMA) // optional comma between attributes
	}

	return p.expectError(TOKEN_RBRACE)
}

// Helper methods.
func (p *Parser) current() Token {
	if p.pos >= len(p.tokens) {
		return Token{Type: TOKEN_EOF}
	}
	return p.tokens[p.pos]
}

func (p *Parser) peek(offset int) Token {
	pos := p.pos + offset
	if pos >= len(p.tokens) {
		return Token{Type: TOKEN_EOF}
	}
	return p.tokens[pos]
}

func (p *Parser) prev() Token {
	if p.pos == 0 {
		return Token{}
	}
	return p.tokens[p.pos-1]
}

func (p *Parser) advance() Token {
	token := p.current()
	p.pos++
	return token
}

// parseIfBlock parses a top-level IF/THEN/FI block.
func (p *Parser) parseIfBlock() ([]CompositionOpNode, error) {
	var thenOps []CompositionOpNode
	var elseOps []CompositionOpNode

	expr, err := p.parseBooleanExpression()
	if err != nil {
		return nil, err
	}

	if !p.expect(TOKEN_THEN) {
		return nil, p.errorf("expected 'THEN' after IF condition")
	}

	for !p.eof() && p.current().Type != TOKEN_ELSE && p.current().Type != TOKEN_FI {
		subOp := p.currentCompositionOp()
		if subOp != nil {
			thenOps = append(thenOps, *subOp)
		} else if p.match(TOKEN_SAY) {
			msg := ""
			if !p.eof() && (p.current().Type == TOKEN_STRING_CONSTANT || p.current().Type == TOKEN_CNAME) {
				msg = p.current().Value
				p.advance()
			}
			op := CompositionOpNode{Type: "SAY", Message: msg}
			thenOps = append(thenOps, op)
		} else if p.current().Value == "MARK" || p.current().Value == "CHECK" {
			p.advance()              // skip MARK/CHECK keyword
			p.match(TOKEN_SEMICOLON) // consume optional semicolon
		} else {
			p.advance() // skip unknown token
		}
	}

	if p.match(TOKEN_ELSE) {
		for !p.eof() && p.current().Type != TOKEN_FI {
			subOp := p.currentCompositionOp()
			if subOp != nil {
				elseOps = append(elseOps, *subOp)
			} else if p.match(TOKEN_SAY) {
				msg := ""
				if !p.eof() && (p.current().Type == TOKEN_STRING_CONSTANT || p.current().Type == TOKEN_CNAME) {
					msg = p.current().Value
					p.advance()
				}
				op := CompositionOpNode{Type: "SAY", Message: msg}
				elseOps = append(elseOps, op)
			} else if p.current().Value == "MARK" || p.current().Value == "CHECK" {
				p.advance()              // skip MARK/CHECK keyword
				p.match(TOKEN_SEMICOLON) // consume optional semicolon
			} else {
				p.advance() // skip unknown token
			}
		}
	}

	if !p.expect(TOKEN_FI) {
		return nil, p.errorf("expected 'FI' to close IF block")
	}

	// Handle optional semicolon after FI (e.g., "FI;" in Example10)
	p.match(TOKEN_SEMICOLON)

	op := CompositionOpNode{
		Type:       "IF_THEN_ELSE",
		Condition:  expr,
		ThenBranch: thenOps,
		ElseBranch: elseOps,
	}
	return []CompositionOpNode{op}, nil
}

// parseTopLevelShare parses a top-level SHARE clause: "A, B SHARE ALL X, Y;"
func (p *Parser) parseTopLevelShare(schema *SchemaNode) {
	var events []string

	for !p.eof() && p.current().Type != TOKEN_SEMICOLON {
		if p.match(TOKEN_ALL) || p.match(TOKEN_FROM) {
			continue
		}

		if p.current().Type == TOKEN_CNAME {
			events = append(events, p.current().Value)
			p.advance()
		} else if p.current().Type != TOKEN_COMMA && p.current().Type != TOKEN_WS {
			break // stop at non-comma, non-whitespace tokens
		}

		p.match(TOKEN_COMMA) // optional comma between events
	}

	if !p.expect(TOKEN_SEMICOLON) {
		return
	}

	// Create a coordinate with the share operation
	op := CompositionOpNode{Type: "SHARE_ALL"}
	for _, ev := range events {
		op.Message += ev + ", "
	}
	schema.Coordinates = append(schema.Coordinates, &CoordinateNode{Operations: []CompositionOpNode{op}})
}

func (p *Parser) eof() bool {
	return p.current().Type == TOKEN_EOF
}

func (p *Parser) match(expected TokenType) bool {
	if p.current().Type == expected {
		p.advance()
		return true
	}
	return false
}

func (p *Parser) expect(expected TokenType) bool {
	if p.match(expected) {
		return true
	}
	p.addError(p.errorf("expected %v, got %v", tokenName(expected), p.current().Value))
	return false
}

func (p *Parser) expectError(expected TokenType) error {
	if !p.match(expected) {
		return p.errorf("expected %s, got %s", tokenName(expected), p.current().Value)
	}
	return nil
}

func (p *Parser) errorf(format string, args ...any) ParseError {
	msg := fmt.Sprintf(format, args...)
	return ParseError{Token: p.current(), Message: msg}
}

func (p *Parser) addError(err ParseError) {
	p.errors = append(p.errors, err)
}

// tokenName returns a human-readable name for a token type.
func tokenName(t TokenType) string {
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
	case TOKEN_TO:
		return "'TO'"
	case TOKEN_DO:
		return "'DO'"
	case TOKEN_OD:
		return "'OD'"
	case TOKEN_ATTRIBUTES:
		return "'ATTRIBUTES'"
	case TOKEN_BUILD:
		return "'BUILD'"
	case TOKEN_CHECK:
		return "'CHECK'"
	case TOKEN_ONFAIL:
		return "'ONFAIL'"
	case TOKEN_SAY:
		return "'SAY'"
	case TOKEN_SET:
		return "'SET'"
	case TOKEN_MAP:
		return "'MAP'"
	case TOKEN_NUMBER:
		return "'NUMBER'"
	case TOKEN_INTERVAL:
		return "'INTERVAL'"
	case TOKEN_BOOLEAN:
		return "'BOOLEAN'"
	default:
		return fmt.Sprintf("token type %d", t)
	}
}

// isRelationName checks if a string is a known relation name.
func isRelationName(name string) bool {
	switch strings.ToUpper(name) {
	case "PRECEDES", "IN":
		return true
	default:
		return false
	}
}
