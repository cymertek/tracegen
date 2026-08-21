/* Composite events with shared atomic events scaled using 
    iteration. Technique developed by John Phillips in 
    "Model of an Unmanned Undersea Vehicle (UUV) Search 
    Mission Proposed Rendezvous Task," May 2023). 
    Run for scopes 1-5. */

SCHEMA Scaling_Composite_Events_with_Shared_Atomic_Events_Using_Iteration

ROOT A: {+ B +};

B:	C;

COORDINATE	$b1: B FROM A	 
	DO COORDINATE 	$x: C FROM $b1
		DO COORDINATE $b2: B FROM A	
			DO COORDINATE $y: C FROM $b2
				DO 	SHARE $x $y; OD;
			OD;
		OD;
	OD;