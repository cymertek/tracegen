/*  Example 33
    Compiler front end, bottom-up parser
	Lexer and parser in interactive mode.
    
    Example of UML-like Component Diagram extracted 
    from the set of valid event traces
	The MP code for constructing UML-like Component Diagram 
    is reusable and can be copied/pasted into any MP model.
    
	run for 
	scope 1, 20 traces, approx. 5 sec.

====================================================*/
SCHEMA compiler_example

ROOT Source_code: (+<1.. $$scope + 1> 
    					get_characters 
    				 	unget_some_characters +)
;

/*============= lexical analysis ===============*/
RegExpr_match:  match_string 
                [ put_token ]
;

Token_recognition: 	
					get_characters
					{+ RegExpr_match +}
					unget_some_characters 
BUILD{
	/* only one RegExpr_match succeeds */
	ENSURE #put_token == 1;
};

ROOT Lexer:     (+<1..2 * $$scope> Token_recognition +) ;

Source_code, Lexer SHARE ALL get_characters, unget_some_characters;

/*================ bottom-up parsing ===============*/
Shift:  Push
        get_token
;

Reduce: (*<0..3> Pop *) 
    /* <0..3> is needed to tame the combinatorial explosion for nested iterations */
        Push 
;

ROOT Parser:
	Push /* push the start non-terminal symbol */ 

    /* Shift_Reduce */
	(+<1..$$scope + 1>
        get_token
	 	[ Shift ]
		Reduce 
        [ Put_node]	
	+)
	(	Parsing_complete 	|
		Report_syntax_error	)
;

/*--- lexer and parser in the interactive mode ---*/
COORDINATE 	$produce_token: put_token FROM Lexer,
			$consume_token: get_token FROM Parser
	DO ADD $produce_token PRECEDES $consume_token; OD;

/*==================================================*/
ROOT Stack: (*<2 .. 2 * $$scope + 1 > (Push | Pop) *)
	/* extended iteration to provide 
		sufficient number of Pop and Push events */
BUILD{	ENSURE FOREACH $x: Pop 
				#Pop BEFORE $x < #Push BEFORE $x; } 
;

Parser, Stack SHARE ALL Pop, Push;

/*==================================================*/
ROOT Abstract_syntax_tree: (*<0..2 * $$scope> Put_node *);

Parser, Abstract_syntax_tree SHARE ALL Put_node;

/*================================================================
 Processing event trace to find dependencies between components.
 Produces a UML-like Component Diagram. This code is reusable, 
 and can be copied/pasted into any other MP model.
  ================================================================*/
GRAPH Diagram { TITLE ("main component interactions");};

	COORDINATE 	$E1: ($$ROOT | $$COMPOSITE) DO 
		COORDINATE	$E2: ($$ROOT | $$COMPOSITE) DO
			WITHIN Diagram{
    /* For each valid event trace find all root and composite 
        event instances within the event trace and add them to the graph. */ 
		 		Node$a: LAST ($E1);
				Node$b: LAST ($E2);
	/* LAST option in the node constructors ensures
    	there will be only a single instance of a node 
		in the graph for each root and composite event 
        found in the event trace */

	/* If event E1 is IN another event E2, add an arrow “E2 calls E1” */
				IF $E1 IN $E2 THEN
  					ADD Node$b ARROW("calls") Node$a; 
				FI;
	
   /* We look for interactions between components and data structures.

	Interactions between components, usually are represented by coordination of 
	events in the interacting components (presence of PRECEDES between events 
    in different threads).
    
 	Interactions between components and data structures are modeled by shared events, 
    since data structures are usually modeled as a set of operations performed on them. */ 
		
				IF  $E1 !=  $E2 	                        AND
                	NOT ($E1 IN $E2 OR $E2 IN $E1) 			AND
               		(	( EXISTS 	$E3: $$EVENT ($E3 IN $E1 AND $E3 IN $E2) ) OR
                        
  			   			( EXISTS 	$E3: $$EVENT FROM $E1, 
                			  		$E4: $$EVENT FROM $E2 ($E3 PRECEDES $E4) ) ) 	THEN
  			   			ADD Node$a LINE("interacts with") Node$b;
                FI;
            }; /* end WITHIN Diagram */
		OD; 
	OD; /* end of $E1 and $E2 loops */

GLOBAL
/* When trace derivation is completed, data from the traces has been accumulated in
	 the graph and is ready to be shown */
SHOW Diagram;

