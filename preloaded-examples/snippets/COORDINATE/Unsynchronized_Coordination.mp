/*  Unsynchronized coordination for iteration cycles adding
    precedence relation whether they appear in the same cycle
    or not (MP Manual section 4.8)
    SCHEMA S1
    ROOT R1: (+ (A | B) C +);
    ROOT R2: (+ (D | E) F +); */

COORDINATE $a: A FROM R1, $d: D FROM R2
    DO
        ADD $a PRECEDES $d;
    OD;

COORDINATE $b: B FROM R1, $e: E FROM R2
    DO
        ADD $b PRECEDES $e;
    OD;
