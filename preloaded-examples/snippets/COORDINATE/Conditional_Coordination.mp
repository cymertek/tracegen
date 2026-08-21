/*  Conditional coordination adding precedence relation
    only if event B is present in a trace (MP Manual section 4.7)
    ROOT R1: (A | B | C);
    ROOT R2: D; */

IF #B > 0 THEN
    COORDINATE $x: B, $y: D
        DO ADD $x PRECEDES $y; OD;
FI;
