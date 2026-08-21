/*  Conditional coordination adds a precedence relation
    only if a certain condition is met, in this case that 
    event B is present in a trace (MP Manual section 4.7) */

SCHEMA Conditional_coordination

ROOT R1: (A | B | C);
ROOT R2: D; 

IF #B > 0 THEN
    COORDINATE $x: B, $y: D
        DO ADD $x PRECEDES $y; OD;
FI;
