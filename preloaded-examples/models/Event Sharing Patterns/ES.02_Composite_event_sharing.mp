SCHEMA Event_Sharing_for_Composite_Events

ROOT E: { A , B , C };

A:	D;
B:	D;
C:	D;

/*  SHARE ALL shortcut is not for composite event sharing.  
	Use the full coordinate statement below. */

	COORDINATE	$a: A, 
				$b: B, 
				$c: C
	DO COORDINATE $d1: D FROM $a
		DO COORDINATE 	$d2: D FROM $b,
						$d3: D FROM $c
			DO 	SHARE $d1 $d2;
				SHARE $d1 $d3;
			OD;
		OD;
	OD;