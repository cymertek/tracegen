/*  Unsynchronized coordination for iteration cycles add
    precedence relations whether they appear in the same cycle
    or not (MP Manual section 4.8) */

/*  Traces 5 and 6 produced at Scope 2 demonstrate deadlock patterns,
    which if present in a real-time system, are a serious problem
    that need to be addressed in the architecture design
    (model specification). Certain traces at Scopes 3 and above
    demonstrate further examples of deadlock patterns as well. */
    
SCHEMA Unsynchronized_coordination

ROOT R1: (+ (A | B) C +);
ROOT R2: (+ (D | E) F +); 

COORDINATE $a: A FROM R1, $d: D FROM R2
    DO
        ADD $a PRECEDES $d;
    OD;

COORDINATE $b: B FROM R1, $e: E FROM R2
    DO
        ADD $b PRECEDES $e;
    OD;
