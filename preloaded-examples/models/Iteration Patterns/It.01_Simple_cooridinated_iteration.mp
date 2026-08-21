SCHEMA Simple_Coordinated_Iteration

ROOT A:	(* a *); 
ROOT B:	(* b *);

COORDINATE  $x: a		FROM A,
            $y: b		FROM B 
    DO ADD $x PRECEDES $y; OD;