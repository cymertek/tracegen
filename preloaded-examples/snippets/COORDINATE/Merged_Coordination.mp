/*  Merged coordination adding multiple precedence 
    relations at once (MP Manual section 4.4) */
    
COORDINATE  $x: a FROM A,
            $y: b FROM B,
            $z: c FROM C
    DO ADD  $x PRECEDES $y,
            $x PRECEDES $z; OD;
