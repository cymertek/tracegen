/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 31. Model of Petri Net                     │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the modeling of a Petri net in MP.  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a behavior model of the Petri net diagram  │ │
│*│ │ above Example 28 in the MP v.4 Language Manual.    │ │
│*│ │ The template for modeling a Petri net in MP is     │ │
│*│ │ similar to the other finite state machines.        │ │
│*│ │ Behaviors of places and transitions are modeled by │ │
│*│ │ root events, where each transition is represented  │ │
│*│ │ by a pair of events sends_to and receives_from     │ │
│*│ │ containing events send_token and get_token,        │ │
│*│ │ correspondingly. The BUILD block for each place    │ │
│*│ │ behavior ensures that the number of send tokens    │ │
│*│ │ does not exceed the number of received tokens –    │ │
│*│ │ the main condition of the Petri net behavior.      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 28: Modeling Petri net" from Auguston, M. │ │
│*│ │ "Monterey Phoenix System and Software Architecture │ │
│*│ │ and Workflow Modeling Language Manual"             │ │
│*│ │ (Version 4). 2020. Available online:               │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, petri net; event attribute, number;      │ │
│*│ │ report, global                                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ To obtain in the Global view the Petri net diagram │ │
│*│ │ extracted from the event traces, run the model at  │ │
│*│ │ scope 2.                                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 4 traces in approx. 6.6 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Petri_Net
/* 	behavior of each place and transition 
	is modeled by a separate root event */

P1_sends_to_T1: send_token;
P1_receives_from_T2: get_token;

ROOT P1_behavior: 	get_token (*	(* P1_receives_from_T2 *) 
    								P1_sends_to_T1  			*)
		BUILD{ ENSURE FOREACH $s: P1_sends_to_T1 
            	#get_token BEFORE $s > #send_token BEFORE $s;};

ROOT T1_behavior: (* 	T1_receives_from_P1 T1_fires 
    					{T1_sends_to_P2, T1_sends_to_P3} 	*);
T1_sends_to_P2: send_token;
T1_sends_to_P3: send_token;

COORDINATE 	$s: P1_sends_to_T1,
			$r: T1_receives_from_P1
	DO ADD $s PRECEDES $r; OD;

ROOT P2_behavior: (* 	(* P2_receives_from_T1 *) 
    					P2_sends_to_T2  			*)
		BUILD{ ENSURE FOREACH $s: P2_sends_to_T2 
            	#get_token BEFORE $s > #send_token BEFORE $s;};
P2_receives_from_T1: get_token;
P2_sends_to_T2: send_token;

COORDINATE 	$s: T1_sends_to_P2,
			$r: P2_receives_from_T1
	DO ADD $s PRECEDES $r; OD;

ROOT P3_behavior: 	get_token get_token 
					(* 	(* P3_receives_from_T1 *) 
    					P3_sends_to_T2 				*)
		BUILD{ ENSURE FOREACH $s: P3_sends_to_T2 
            	#get_token BEFORE $s > #send_token BEFORE $s;};
P3_receives_from_T1: get_token;
P3_sends_to_T2: send_token;

COORDINATE 	$s: T1_sends_to_P3,
			$r: P3_receives_from_T1
	DO ADD $s PRECEDES $r; OD;

ROOT T2_behavior: (* 	{T2_receives_from_P2, T2_receives_from_P3} T2_fires 
    					[{T2_sends_to_P1, T2_sends_to_P4}] 	*);
/* T2_sends_to events are made optional to terminate the loop from T2 to P1*/
T2_sends_to_P1: send_token;
T2_sends_to_P4: send_token;

COORDINATE 	$s: P2_sends_to_T2,
			$r: T2_receives_from_P2
	DO ADD $s PRECEDES $r; OD;

COORDINATE 	$s: P3_sends_to_T2,
			$r: T2_receives_from_P3
	DO ADD $s PRECEDES $r; OD;

COORDINATE 	$s: T2_sends_to_P1,
			$r: P1_receives_from_T2
	DO ADD $s PRECEDES $r; OD;

ROOT P4_behavior: get_token (* P4_receives_from_T2 *);
P4_receives_from_T2: get_token;

COORDINATE 	$s: T2_sends_to_P4,
			$r: P4_receives_from_T2
	DO ADD $s PRECEDES $r; OD;

COORDINATE $b: (P1_behavior | P2_behavior | P3_behavior | P4_behavior)
	DO SAY("At the end of simulation place " $b " has " 
        #get_token FROM $b - #send_token FROM $b " tokens");
    OD;
/*================================================================
	Building Petri net diagram
=================================================================*/
GRAPH Diagram { TITLE ("Petri net diagram");};
ATTRIBUTES {number initial_tokens;};

WITHIN Diagram{
  COORDINATE $a: $$ROOT DO
	Node$f: LAST($a);
    
	$a.initial_tokens := 
	   #{$t: get_token FROM $a SUCH THAT #send_token BEFORE $t == 0};
    
	IF $a.initial_tokens > 0 THEN 
		ADD LAST("Start") ARROW("initial " $a.initial_tokens " tokens") Node$f;
    FI;

	COORDINATE $b: $$ROOT DO
    	IF  $a != $b AND 
            /* looking for $c: A_sends_to_B and $d: B_receives_from_A events */
            EXISTS $c: $$COMPOSITE FROM $a, $d: $$EVENT FROM $b ($c PRECEDES $d)
    	THEN ADD Node$f ARROW(1) LAST($b); FI;
	OD;
  OD;
}; /* end WITHIN */

GLOBAL
SHOW Diagram;
