/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Replay Attack                             │ │
│*│ │  Created by Mikhail Auguston in 2019.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate MP modeling of a replay attack       │ │
│*│ │ involving data transmission.                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates a well known attack        │ │
│*│ │ strategy on a communication system. Users may use  │ │
│*│ │ this model as an example way to model possible 3rd │ │
│*│ │ parties listening in other systems.                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 20: Simple MP model for the Replay        │ │
│*│ │    Attack." from Auguston, M. "Monterey Phoenix    │ │ 
│*│ │    System and Software Architecture and Workflow   │ │
│*│ │    Modeling Language Manual" (Version 4). 2020.    │ │
│*│ │    Available online:                               │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Replay attack." Wikipedia. Wikimedia Foundation,  │ │
│*│ │    July 1, 2021.                                   │ │
│*│ │    https://en.wikipedia.org/wiki/Replay_attack     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, replay attack;                           │ │
│*│ │ behavior, message eavesdropping;                   │ │
│*│ │ coordination, event                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 12 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Replay_Attack

ROOT Alice:
	sends_password_to_Bob 
	
	(* 	presents_Alice_password 
    	talks 			*)
;

/*---------------------------------------*/
ROOT Network:
	message_in_transit
;

COORDINATE 	$a: sends_password_to_Bob 	FROM Alice,
			$n: message_in_transit 		FROM Network
	DO ADD $a PRECEDES $n; OD;

/*---------------------------------------*/
/* Eavesdropper */
ROOT Eve:
	eavesesdrops_message
	(+ 	presents_Alice_password 
    	talks 			+)
;

COORDINATE 	$n: message_in_transit 		FROM Network,
			$e: eavesesdrops_message 	FROM Eve
	DO ADD $n PRECEDES $e; OD; 

/*---------------------------------------*/

ROOT Bob:
	requests_password_from_Alice
	receives_password_from_Alice
	
	(*<1.. 2 * $$scope>	asks_for_password
        talks *)
;

COORDINATE 	$a1: requests_password_from_Alice 	FROM Bob,
			$r1: sends_password_to_Bob 			FROM Alice
	DO ADD $a1 PRECEDES  $r1; OD;

COORDINATE 	$n: message_in_transit 				FROM Network,
			$b: receives_password_from_Alice 	FROM Bob
	DO ADD $n PRECEDES $b; OD;

COORDINATE 	$a: asks_for_password FROM Bob,
			$p: presents_Alice_password /* not necessary to give the FROM owner, 
            							just the event name is sufficient */
	DO ADD $a PRECEDES $p; OD;

COORDINATE 	$t1: talks SUCH THAT NOT $t1 FROM Bob,
			$t2: talks FROM Bob
	DO SHARE $t1 $t2;  OD;
