SCHEMA Multiple_to_One_Nested

ROOT Swarm: {+ UAV +};
    UAV: Store_SubSwarm_ID;
	
ROOT Flight_Crew: Confirm_All_UAVs_Staged;

COORDINATE 	$a: Store_SubSwarm_ID			    FROM Swarm 
	DO	 COORDINATE $b: Confirm_All_UAVs_Staged	FROM Flight_Crew
 			DO ADD $a PRECEDES $b; OD;
 	OD;
