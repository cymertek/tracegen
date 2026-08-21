SCHEMA Asynchronous_Coordination

ROOT Sender:	Send Send Send; 
ROOT Receiver:	Receive Receive Receive;

COORDINATE		$x: Send FROM Sender,
			<!>	$y: Receive FROM Receiver 
    DO ADD $x PRECEDES $y; OD;