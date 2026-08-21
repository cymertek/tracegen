/*  Simple coordination adding a precedence relation 
    between events in different roots.  FROM clause is
    optional when there is no reuse of same event name
    in different roots. (MP Manual sections 2.3, 4.4) */

SCHEMA Simple_coordination

ROOT A: a;
ROOT B: b;

COORDINATE   $x: a FROM A,
             $y: b FROM B
    DO ADD $x PRECEDES $y; OD;
