/*  Batch coordination uses multiple ADD operations in a
    single coordination operation to add multiple
    precedence relations at once. Caution: traces missing
    any of the events assigned to variables will be rejected.
    (MP Manual section 4.4) */

SCHEMA Batch_coordination

ROOT A: a;
ROOT B: b;
ROOT C: c;
    
COORDINATE  $x: a FROM A,
            $y: b FROM B,
            $z: c FROM C
    DO ADD  $x PRECEDES $y,
            $y PRECEDES $z; OD;