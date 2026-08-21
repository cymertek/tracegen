/*  Example13_FiniteStateDiagram.mp

    example of finite state diagram behavior model,
    contains non-deterministic transitions (from S1 with symbol a), 
    and a single state loop (S3 with a).
    
    The finite state transition diagram:
    
    Start -> S1
    S1 -> a -> S3
    S1 -> a -> S4
    S1 -> b -> S4
    S2 -> b -> S1
    S2 -> End
    S3 -> a -> S3
    S3 -> b -> S4
    S4 -> a -> S2
    
    Direct modeling of the state diagram including state visits 
	and actions triggering state transitions. Only paths starting 
    with Start and ending with End are valid.
    
    Behavior of each state Si is represented by a separate 
    root event Si_behavior.
    
    Each transition in the diagram Si -> Sj is modeled by a 
    composite event Si_to_Sj.
    
    1) Event Si_to_Sj contains the symbol triggering the transition. 
    2) Si_to_Sj is shared by corresponding state behavior roots.
     
    run for: 
    scope 1 (4 traces),
    scope 2 (30 traces),
    scope 3 (258 traces)
*/

SCHEMA FiniteStateDiagram

S1_to_S3: a;
S1_to_S4: (a | b);

ROOT S1_behavior:  	Start S1 
					(* (S1_to_S3 | S1_to_S4) S2_to_S1 S1 *) 
					(S1_to_S3 | S1_to_S4);

S2_to_S1: b;

ROOT S2_behavior:  	(* S4_to_S2 S2 S2_to_S1  *) 
					S4_to_S2 S2 End;

S1_behavior, S2_behavior SHARE ALL S2_to_S1;

/* coordination should be done as soon as possible,
	in order to prune the search, 
	but only after both root S1_behavior and S2_behavior 
	traces are available */

S3_to_S3: a;
S3_to_S4: b;

ROOT S3_behavior: (* 	S1_to_S3 S3 
    					(* S3_to_S3 S3 *)
    					S3_to_S4 			*) ;

S3_behavior, S1_behavior SHARE ALL S1_to_S3;

S4_to_S2: a;

ROOT S4_behavior: (* (S1_to_S4 | S3_to_S4) S4 
    					 S4_to_S2 *) ;

S4_behavior, S1_behavior SHARE ALL S1_to_S4;
S4_behavior, S2_behavior SHARE ALL S4_to_S2;
S4_behavior, S3_behavior SHARE ALL S3_to_S4;

SAY("The path: ");
/* Sort state visits and transition events according to the BEFORE relation and then show them */
COORDINATE 	<SORT> $a: (S1 | S2 | S3 | S4 | a | b | Start | End)
	DO SAY($a); OD;
