/* Example 1a
Unreliable message flow.

We may want to specify behaviors when some messages get lost in the transition. 
It can be done using ‘virtual’ events.

run for scopes 1 and up.

*/
SCHEMA unreliable_message_flow
ROOT 	Sender: 	(* send *);
ROOT 	Receiver: 	(* (receive | does_not_receive) *);

COORDINATE 	$x: send 							FROM Sender, 
			$y: (receive | does_not_receive)	FROM Receiver 
	DO 	ADD $x PRECEDES $y; OD;
