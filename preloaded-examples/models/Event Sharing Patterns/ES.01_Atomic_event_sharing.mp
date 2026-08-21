SCHEMA Event_Sharing_for_Atomic_Events

ROOT A:	D;
ROOT B:	D;
ROOT C: D;

A, B, C SHARE ALL D;

/* The equivalent expanded form for the above SHARE ALL statement 
	follows.  To use it, comment out the SHARE ALL statement and 
	comment in the following statement. */

/*COORDINATE	$a: D FROM A
	DO COORDINATE	$b: D FROM B,
					$c: D FROM C 
		DO 	SHARE $a $b;
			SHARE $a $c; OD;
	OD;
*/