/*  Branch coordination adds precedence relations 
    between events in corresponding branches. The 
    number of coordinated branches may be greater than two. */

SCHEMA Branch_coordination

ROOT A: ( a1 | a2 );
ROOT B: ( b1 | b2 );

COORDINATE   $x: a1 FROM A,
             $y: b1 FROM B
    DO ADD $x PRECEDES $y; OD;

COORDINATE   $x: a2 FROM A,
             $y: b2 FROM B
    DO ADD $x PRECEDES $y; OD;
