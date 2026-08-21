/*  Relaxed coordination adds a precedence relation 
    between an event in one root and alternate events
    in a different root. The number of alternate events 
    may be greater than two. */

SCHEMA Relaxed_coordination

ROOT A: a;
ROOT B: ( b1 | b2 );

COORDINATE   $x: a FROM A,
             $y: ( b1 | b2 ) FROM B
    DO ADD $x PRECEDES $y; OD;
