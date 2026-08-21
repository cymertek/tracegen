/* 	Example 28
 	MP compiler/trace generator architecture model 
    
    run for scope 1 or more
    
===================================================*/
SCHEMA MP_architecture

ROOT User:
	(+ 	[ load_MP_file ]
		( MP_model_editing | browsing_MP_code )
		press_RUN_button
		(	browse_event_trace 		| 
			syntax_errors_detected  )
		[ save_MP_file ]
	+)
	end_of_session
;
/*--------------------------------------------------*/

ROOT MP_code_editor:
	(+  
		( 	MP_model_editing | 
			browsing_MP_code )
	+)
;

User, MP_code_editor SHARE ALL MP_model_editing, browsing_MP_code;

/*--------------------------------------------------*/

ROOT MP_GUI:
	(+ 	[ load_MP_file ]
		press_RUN_button
		input_MP_code
		/* trace visualization happens only if there are no syntax errors, 
			and trace generator has been called */
		( receive_json_file
		  visualize_trace 			|

          syntax_errors_detected 	)
		[ save_MP_file ]
	+)
;

User, MP_GUI SHARE ALL load_MP_file, save_MP_file,
						press_RUN_button;

COORDINATE 	$v: visualize_trace,
			$b: browse_event_trace 	 
	DO ADD $v PRECEDES $b; OD;

/*--------------------------------------------------*/

ROOT MP_parser:
	(+	input_MP_code
		perform_syntax_analysis
		( 	write_abstract_syntax_tree  |
			syntax_errors_detected      )
	+)
;

MP_parser, MP_GUI SHARE ALL input_MP_code;

User, MP_parser, MP_GUI SHARE ALL syntax_errors_detected;

COORDINATE 	$p: press_RUN_button,
			$r: input_MP_code
	DO ADD $p PRECEDES $r; OD;
/*--------------------------------------------------*/

ROOT Abstract_syntax_tree:
	(* 	write_abstract_syntax_tree
		read_abstract_syntax_tree 
	*);

MP_parser, Abstract_syntax_tree SHARE ALL write_abstract_syntax_tree;
/*--------------------------------------------------*/

ROOT Trace_generator:
	(* 	read_abstract_syntax_tree
		generate_Cpp_file
		run_Cpp_compiler
		run_executable
		produce_json_file
	*);

Abstract_syntax_tree, Trace_generator SHARE ALL read_abstract_syntax_tree;

COORDINATE 	$p: produce_json_file, 
			$r: receive_json_file
	DO ADD $p PRECEDES $r; OD;
/*--------------------------------------------------*/

/* trace annotations */
SAY(" Scope " $$scope " Trace #" trace_id );

/*================================================================
 Processing event trace to find dependencies between components.
 Produces a UML-like Component Diagram. This code is reusable, 
 and can be copied/pasted into any other MP model.
 See Sec. 5.3 in MP v.4 Manual
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

