SCHEMA Multiple_to_One

ROOT A: B C;
ROOT D: E;

COORDINATE 	$a: B	FROM A,   
			$b: E	FROM D
	DO	ADD $a PRECEDES $b; OD;
		
COORDINATE 	$a: C	FROM A,   
			$b: E	FROM D
	DO	ADD $a PRECEDES $b; OD;
