/* 
Example1_simple_message_flow.mp
	 
Event grammar rules for each root define derivations for event traces,
in this case a simple sequence of zero or more events for each root.

The COORDINATE composition takes two root traces and produces 
a modified event trace, merging behaviors of Sender and Receiver 
and adding the PRECEDES relation for the selected send/receive pairs.
The coordination operation behaves as a "cross-cutting" derivation rule.

Run for scopes 1 and up. The "Sequence" or "Swim Lanes" layouts are 
the most appropriate for browsing traces here.

*/

SCHEMA simple_message_flow

ROOT Sender:   (* send *);
ROOT Receiver: (* receive *);

COORDINATE	$x: send 	FROM Sender, 
			$y: receive FROM Receiver
	DO ADD $x PRECEDES $y; OD;
