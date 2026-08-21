/*
 	Kristin Giammarco and Mikhail Auguston
  MP Model based on "Swarm CONOPs" Draft 11 February 2015 
	11 February 2015 - Initial Model Started by KGiammarco
    25 May 2015 - M.Auguston Merged several COORDINATE, SHARE ALL to speed up 
    	trace generation
    22 July 2015 - added a few more coordinate statements to capture dependencies 

	This model demonstrates how to get several instances of the same actor (UAV) 
    coordinated with external events (run for scopes 2 and 3 to see 2 and 3 UAVs, 
    respectively).
*/

SCHEMA Swarm_UAV

ROOT Flight_Crew: 	Conduct_PreMission_Briefing
					(+ PreFlight_UAV +) 					
					Confirm_Staging_Plans 					
					(+ 	Confirm_Launch_Permission 			
            			Launch_UAV 								
						Assess_Flight_Behavior
						Confirm_Nominal_Flight_Behavior 		
						Stage_UAV_for_Ingress +) 			

					Alert_All_UAVs_Staged
			
					(* [ Receive_Recovery_Prioritization_List ] 
                        /* above optional event will always occur because it is 
                        COORDINATEd with a mandatory event */  
                		
                        Observe_New_UAV_in_Recovery_List 		
               		 	Recover_UAV 							
						Retrieve_UAV
						Alert_RC_UAV_Landing *) 			
					
					Confirm_UAVs_Recovered_Retrieved
					Conduct_PostMission_Hotwash;

ROOT Swarm: {+ UAV +};

   UAV:	Undergo_PreFlight
		Launch
		Report_Flight_Status
		Confirm_Staged_for_Ingress
		Store_Ingress_SubSwarm_ID  
		Perform_Mission
		Store_Egress_SubSwarm_ID
		Confirm_Staged_for_Egress
		Land;

COORDINATE 	$a: PreFlight_UAV		FROM Flight_Crew, 
			$b: Undergo_PreFlight	FROM Swarm
		DO ADD $a PRECEDES $b; OD;  			

COORDINATE 	$a: Launch_UAV	FROM Flight_Crew, 
			$b: Launch 		FROM Swarm
		DO ADD $a PRECEDES $b; OD;					

COORDINATE 	$a: Report_Flight_Status 	FROM Swarm, 
			$b: Assess_Flight_Behavior	FROM Flight_Crew
		DO ADD $a PRECEDES $b; OD;					

COORDINATE 	$a: Stage_UAV_for_Ingress				FROM Flight_Crew, 
			$b: Confirm_Staged_for_Ingress			FROM Swarm
		DO ADD $a PRECEDES $b; OD;			

COORDINATE 	$a: Confirm_Staged_for_Egress 			FROM Swarm,  
			$b: Observe_New_UAV_in_Recovery_List	FROM Flight_Crew
		DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Recover_UAV	FROM Flight_Crew, 
			$b: Land 		FROM Swarm
		DO ADD $b PRECEDES $a; OD;				

ROOT Mission_Commander:	Conduct_PreMission_Briefing
                        Confirm_Staging_Plans
						Confirm_Swarm_Mission_Plan
						(* Confirm_Launch_Permission *)
						Conduct_PostMission_Hotwash; 

Flight_Crew, Mission_Commander SHARE ALL Confirm_Staging_Plans, Confirm_Launch_Permission;		
			

COORDINATE 	$a: Confirm_UAVs_Recovered_Retrieved	FROM Flight_Crew, 
			$b: Conduct_PostMission_Hotwash			FROM Mission_Commander
		DO ADD $a PRECEDES $b; OD;				


ROOT Swarm_Operator:	Conduct_PreMission_Briefing
			Confirm_Swarm_Mission_Plan 				
			Receive_Swarm_Mission_Plan_Approval		
			(+ Assign_Ingress_SubSwarmID +) 		
			Confirm_All_UAVs_Staged
			Command_Swarm_to_Commence_Mission						
			(* Assign_Egress_SubSwarmID *) 			
			Provide_Recovery_Prioritization_List 	
			Conduct_PostMission_Hotwash;
			   
Mission_Commander, Swarm_Operator SHARE ALL Confirm_Swarm_Mission_Plan;				

COORDINATE  	$a: Confirm_Staged_for_Ingress		FROM Swarm, 
				$b: Assign_Ingress_SubSwarmID		FROM Swarm_Operator,
				$c: Store_Ingress_SubSwarm_ID		FROM Swarm

		DO  ADD $a PRECEDES $b; 
		    ADD $b PRECEDES $c;
		OD;	
	
COORDINATE 	$a: Store_Ingress_SubSwarm_ID			FROM Swarm 
	DO	 COORDINATE $b: Alert_All_UAVs_Staged	FROM Flight_Crew
 			DO ADD $a PRECEDES $b; OD;
 	OD;

COORDINATE 	$a: Alert_All_UAVs_Staged		FROM Flight_Crew,
			$b: Confirm_All_UAVs_Staged		FROM Swarm_Operator
		DO ADD $a PRECEDES $b; OD;				

COORDINATE 	$a: Command_Swarm_to_Commence_Mission	FROM Swarm_Operator 
	DO	 COORDINATE  $b: Perform_Mission		FROM Swarm 
 			DO ADD $a PRECEDES $b; OD;
 	OD;	

COORDINATE 	$a: Assign_Egress_SubSwarmID		FROM Swarm_Operator, 
			$b: Store_Egress_SubSwarm_ID		FROM Swarm
		DO ADD $a PRECEDES $b; OD;			

COORDINATE 	$a: Provide_Recovery_Prioritization_List	FROM Swarm_Operator, 
			$b: Receive_Recovery_Prioritization_List	FROM Flight_Crew
		DO ADD $a PRECEDES $b; OD;				

ROOT Range_Control: 	(* Receive_UAV_Landing_Notification *);

COORDINATE 	$a: Alert_RC_UAV_Landing		FROM Flight_Crew, 
			$b: Receive_UAV_Landing_Notification	FROM Range_Control
		DO ADD $a PRECEDES $b; OD;				

ROOT Safety_Coordinator: Conduct_PreMission_Briefing
			 Conduct_PostMission_Hotwash;

Flight_Crew, Mission_Commander, Swarm_Operator, Safety_Coordinator SHARE ALL 
		Conduct_PreMission_Briefing, Conduct_PostMission_Hotwash;
