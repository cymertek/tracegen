SCHEMA Coordinated_Iteration_with_Replication_and_Repetition

ROOT A:	(+ a +);
ROOT B: {+ b +};
    b: (+ c +);

/* The following nested COORDINATE statements add a precedence
	relation between a pair of activities a from A and each c from 
    b for each instance of b from B. */

COORDINATE $z: b FROM B
	DO	
		COORDINATE 	$x: a FROM A,
				  	$y: c FROM $z
			DO ADD $x PRECEDES $y;	OD;
    OD;