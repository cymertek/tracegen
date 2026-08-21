/*  Example14, microwave_oven.mp

    example of finite state diagram behavior model, 
	CTL formula representation in MP, and model checking for a small scope.
       
    Microwave oven example from E.Clarke, O.Grumberg, D.Peled 
    "Model Checking". MIT Press, 1999, pp. 38-39.
    
    S1 - start & end state
    
    Transitions:
    S1 -> start_oven -> S2
    S1 -> close_door -> S3
    S2 -> close_door -> S5
    S3 -> open_door  -> S1
    S3 -> start_oven -> S6
    S4 -> open_door  -> S1
    S4 -> done  	 -> S3
    S4 -> cook  	 -> S4
    S5 -> open_door  -> S2
    S5 -> reset  	 -> S3
    S6 -> warm_up  	 -> S7
    S7 -> start_cooking  -> S4

    State diagram converted into regular expressions, 
    or paths, including state visits 
	and commands triggering state transitions, 
    following well known algorithm  NFA -> RE.
     
    run for: 
    scope 1 (28 traces, 2 counterexamples, 1.75 sec.)
*/

SCHEMA oven

ROOT Microwave: S1 (*  R7 S1 *);

/* regular expressions, or paths, including state visits 
	and actions triggering state transitions 			
========================================================*/
/*  eliminating S7, paths from S6 to S4 via S7 */
R1: warm_up S7 start_cooking;

/*  eliminating S6, paths from S3 to S4 via S6 */
R2: start_oven S6 R1;

/*  eliminating S5, paths from S2 to S3 via S5 */
R3: close_door S5 reset;

/*  eliminating S5, paths from S2 to S2 via S5 */
R4: close_door S5 open_door;

/*  eliminating S2, paths from S1 to S3 via S2 */
R5: start_oven S2 (* R4 S2 *) R3;

/*  eliminating S4, paths from S3 to S1 via S4 */
R6: R2 S4 (* cook S4 *) open_door;

/*  eliminating S3, paths from S1 to S1 via S3 */
R7: (close_door | R5) S3 
	(* R2 (* S4 cook *) S4 done S3 *) 
	(open_door | R6);

/* States with atomic propositions represented as inner events,
    absence of atomic proposition implies its negation
===============================================================*/
S1:; 				/* ~Start, ~Close, ~Heat, ~Error */

S2: {Start, Error}; /* Start, ~Close, ~Heat, Error */

S3: Close; 			/* ~Start, Close, ~Heat, ~Error */

S4: {Close, Heat}; 	/* ~Start, Close, Heat, ~Error */

S5: {Start, Close, Error}; /* Start, Close, ~Heat, Error */

S6: {Start, Close}; /* Start, Close, ~Heat, ~Error */

S7: {Start, Close, Heat}; /* Start, Close, Heat, ~Error */

/* MP assertion to check CTL formula AG(Start -> AF Heat) 
==========================================================*/
CHECK (FOREACH $s: Start EXISTS $h: Heat 	$h AFTER $s)
	ONFAIL SAY("no Heat after Start detected");


/**************  create Path view 	***********************/
/* show the sequence of states and commands in precedence order */
/*==============================================================*/
COORDINATE 	<SORT> $a: (S1 | S2 | S3 | S4 | S5 | S6 | S7 |
						warm_up | start_cooking | start_oven  | 
    					close_door | reset | open_door | cook | done)
	DO SAY($a); OD;
