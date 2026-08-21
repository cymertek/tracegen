/* Example 35.

    Adding path and state transition diagrams to 
	the Finite Automaton behavior model.
    
    run for scope 2
==========================================================*/
SCHEMA Finite_State_Diagram_with_path

ROOT S1_behavior:  	
			Start 	Start_to_S1 	S1 
			(* (S1_to_S3 | S1_to_S4) 	S2_to_S1 	S1 *) 
			(S1_to_S3 | S1_to_S4);
Start_to_S1: 	empty;
S1_to_S3: 		a;
S1_to_S4: 		(a | b);

ROOT S2_behavior:  
			(* S4_to_S2 	S2 	S2_to_S1  *) 
			S4_to_S2 S2 	
			S2_to_End End;
S2_to_S1: 		b;
S2_to_End: 		empty;

S1_behavior, S2_behavior SHARE ALL S2_to_S1; 

ROOT S3_behavior: 
			(* 	S1_to_S3 S3 
    			(* S3_to_S3 S3 *)
    			S3_to_S4 				*);
S3_to_S3: 		a;
S3_to_S4: 		b;

S3_behavior, S1_behavior SHARE ALL S1_to_S3;

ROOT S4_behavior: 
			(* 	(S1_to_S4 | S3_to_S4) 	S4 
    			S4_to_S2 						*);
S4_to_S2: 		a;

S4_behavior, S1_behavior SHARE ALL S1_to_S4;
S4_behavior, S2_behavior SHARE ALL S4_to_S2;
S4_behavior, S3_behavior SHARE ALL S3_to_S4;

GRAPH Path { TITLE("Path for the event trace"); };
/* The following coordination extracts all triples State-Symbol-State 
	from the trace and accumulates corresponding nodes/transitions 
    in the Path graph. */

CLEAR Path;  /* Path graph is cleared before a new event trace derivation begins. */

WITHIN Path{
	COORDINATE 
	/* SORT (plain synchronous coordination) performs topological sort 
    	on the selected event set with respect to the transitive closure of 
        PRECEDES (BEFORE relation), and the coordination will follow this ordering. 
        If A BEFORE B holds for events A and B, event A will appear in the sorted 
        sequence before B. This way pairs of states and transitions between them 
        are synchronized. */
		<SORT> $state1:	(Start 	| S1 	| S2 	| S3 	| S4),
		<SORT> $symbol:	(a 		| b 	| empty),
 		<SORT> $state2:	(S1 	| S2 	| S3 	| S4 	| End)

	DO
  		Node$s1: LAST ($state1); 
	/* Assigns to the node variable Node$s1 the last instance of node 
    	with the event name stored in $state1 in this graph, or creates a new node, 
        if such instance does not yet exist */ 	 
 		Node$s2: NEW ($state2);
	/* Creates a new instance of node with name $state2.  As a result, 
    	nodes with the same label (representing the same state in the diagram) 
        may appear repeatedly in the Path graph.  */
		ADD Node$s1 ARROW($symbol) Node$s2;
	OD;

	/* show Path graph for each event trace */
	SHOW Path;
}; /* end WITHIN Path */
 
GRAPH Diagram { TITLE("State transition diagram"); };

WITHIN Diagram{
	/* The following coordination extracts all triples State-Symbol-State from 
    	the trace and accumulates corresponding nodes/transitions in the graph */
	COORDINATE 
		<SORT> $state1:	(Start 	| S1 	| S2 	| S3 	| S4),
		<SORT> $symbol: (a 		| b 	| empty),
   		<SORT> $state2:	(S1 	| S2 	| S3 	| S4 	| End)
	DO
		ADD LAST ($state1) ARROW($symbol) LAST ($state2);
		/* this time nodes with the same label will be unique */
	OD;
}; /* end WITHIN Diagram */

GLOBAL
/* After all valid traces have been derived, show the accumulated diagram */
SHOW Diagram;
