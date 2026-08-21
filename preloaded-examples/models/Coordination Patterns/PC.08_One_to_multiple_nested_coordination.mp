SCHEMA One_to_Multiple_Nested

ROOT Swarm_Operator: Command_Swarm_to_Commence_Mission;

ROOT Swarm: {+ UAV +};
	UAV: Perform_Mission;

COORDINATE 	$a: Command_Swarm_to_Commence_Mission	FROM Swarm_Operator 
	DO	 COORDINATE  $b: Perform_Mission		    FROM Swarm 
 			DO ADD $a PRECEDES $b; OD;
 	OD;	
