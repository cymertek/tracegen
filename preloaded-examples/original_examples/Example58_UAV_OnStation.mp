/*********************************************************************************************

A Model for an Unmanned Aerial Vehicle in the OnStation Phase of an ISR Mission
  
Demonstrates use of concurrent events within a root and annotations with
SAY and MARK

"Comprehensive use case scenario generation: An approach for modeling system 
of systems behaviors" by Kristin Giammarco, Kathleen Giles, and Clifford A. Whitcomb
Paper available at https://ieeexplore.ieee.org/abstract/document/7994950

  created by K.Giammarco on 02-03-2017
  modified by K.Giammarco on 02-04-2017 to remove normal events from failure mode scenarios
  modified by K.Giammarco on 02-05-2017 to add normal events back to failure mode scenarios 
  										and added annotations
  
*********************************************************************************************/


SCHEMA UAV_OnStation


/*-----------------------
  GCS OPERATOR MODEL
-------------------------*/

ROOT GCS_Operator: 	(+ Receive_status
    				   [ Receive_UAV_video ]
					   [ Assess_target
						  ( Target_is_not_of_interest Command_to_resume_search |
                              
                            Target_is_of_Interest Command_target_monitoring ) 	]
						[ Receive_bingo_fuel_status_message ] 
    				+)
						Command_end_of_mission End_search;


/*------------------------------------------------------------------
  UAV MODEL
--------------------------------------------------------------------*/

ROOT UAV: 	/*Reach_OnStation_area*/
			
			{ Stream_video, Search, Monitor_status };
			
     		Stream_video: (* Send_UAV_video *); 
	 		
			Search: Follow_search_pattern
					(*  ( Target_detected 
                          Send_target_info
								( Resume_search_pattern 	| 
                                    
                                  Monitor_target 			)	| 
                        
                          No_target_detected Continue_search 	) 
                    *)

					End_search;
			
			Monitor_status: ( Health_normal [ Detect_bingo_fuel ] 	| 
                				Failure_mode Failsafe_behavior 		);


/*-----------------------
  ENVIRONMENT MODEL
-------------------------*/

ROOT Environment:  (* Present_target_signature *);


/*-----------------------
  INTERACTIONS
-------------------------*/

UAV, GCS_Operator SHARE ALL End_search;

COORDINATE 	$a: ( Health_normal | Failure_mode )	FROM UAV,
			$b: Receive_status						FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Send_UAV_video		FROM UAV,
			$b: Receive_UAV_video	FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Send_target_info		FROM UAV,
			$b: Assess_target			FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Command_to_resume_search	FROM GCS_Operator,
			$b: Resume_search_pattern  		FROM UAV
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Command_target_monitoring	FROM GCS_Operator,
			$b: Monitor_target				FROM UAV
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Detect_bingo_fuel					FROM UAV,
			$b: Receive_bingo_fuel_status_message	FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Present_target_signature 	FROM Environment,
			$b: ( Target_detected | No_target_detected )	FROM UAV
		DO ADD $a PRECEDES $b; OD; 

/*-----------------------
  GENERAL CONSTRAINTS
-------------------------*/

ENSURE #Health_normal > 0 -> #Send_UAV_video > 0;


/*-----------------------
  ANNOTATIONS
-------------------------*/

COORDINATE $s: Stream_video 

	DO	IF #Send_UAV_video IN $s == 0 THEN MARK; 
		FI;
	OD;

IF #Health_normal > 0 THEN
	SAY("UAV health was normal");
FI;

IF #Failure_mode > 0 THEN
	SAY("UAV had a failure mode");
FI;

IF #Send_UAV_video == 0 THEN
	SAY("No streaming video");
FI;

IF #Detect_bingo_fuel > 0 THEN
	SAY("UAV had bingo fuel condition");
FI;

IF #Monitor_target > 0 THEN
	SAY("Target of interest was detected");
FI;

IF #Resume_search_pattern > 0 THEN
	SAY("Target was not mission-related");
FI;

IF #No_target_detected > 0 THEN
	SAY("UAV missed a target signature");
FI;
