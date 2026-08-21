/*  Synchronized coordination for iteration cycles add a
    precedence relation only for events that appear in the
    same cycle (MP Manual section 4.8) */

SCHEMA Synchronized_coordination

ROOT R1: (+ (A | B) C +);
ROOT R2: (+ (D | E) F +); 

COORDINATE  $a: (A | B) FROM R1,
            $d: (D | E) FROM R2
    DO
        IF $a IS A AND $d IS D OR $a IS B AND $d IS E THEN
        /* This pair is selected from the same cycle,since the 
        default event sequence is used for coordination threads */
            ADD $a PRECEDES $d;
            ELSE REJECT; /* otherwise reject the trace under derivation */
        FI;
    OD;
