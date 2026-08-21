SCHEMA One_to_Multiple

ROOT A: B;
ROOT C: D E;

COORDINATE 	$a: B	FROM A,   
			$b: D	FROM C
	DO	ADD $a PRECEDES $b; OD;
		
COORDINATE 	$a: B	FROM A,   
			$b: E	FROM C
	DO	ADD $a PRECEDES $b; OD;
