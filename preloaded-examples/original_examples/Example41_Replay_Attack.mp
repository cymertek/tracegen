/* 	Example 41. The description of Replay Attack
	is available at 
	https://en.wikipedia.org/wiki/Replay_attack

    run scope up to 5
======================================*/

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
