/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of UAV On Station                            │ │
│*│ │  Created by Kristin Giammarco on the 3rd of        │ │
│*│ │     February, 2017.                                │ │
│*│ │  Modified by Kristin Giammarco on the 4th of       │ │
│*│ │     February, 2017 to remove normal events from    │ │
│*│ │     failure mode scenarios.                        │ │
│*│ │  Modified by Kristin Giammarco on the 5th of       │ │
│*│ │     February, 2017 to add normal events back to    │ │
│*│ │     failure mode scenarios and added annotations.  │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the modeling for system of systems   │ │
│*│ │ behaviors that include failure mode scenarios.     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a model for an Unmanned Aerial Vehicle in  │ │
│*│ │ the OnStation Phase of an ISR mission. It          │ │
│*│ │ demonstrates the use of concurrent events within a │ │
│*│ │ root (system of systems) and annotations with SAY  │ │
│*│ │ and MARK in order to improve the clarity of the    │ │
│*│ │ model. Users may use this model as an example of   │ │
│*│ │ COORDINATE, IF, and MARK statement usage in order  │ │
│*│ │ to generate "stories" for traces automatically.    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Giammarco, Kristin, Kathleen Giles, and            │ │
│*│ │ Clifford A. Whitcomb. "Comprehensive use case      │ │
│*│ │ scenario generation: An approach for modeling      │ │
│*│ │ system of systems behaviors." 2017 12th System of  │ │
│*│ │ Systems Engineering Conference (SoSE), June 2017.  │ │
│*│ │ https://doi.org/10.1109/sysose.2017.7994950        │ │
│*│ │ https://ieeexplore.ieee.org/document/7994950       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, UAV; autonomous;                         │ │
│*│ │ behavior, system of systems;                       │ │
│*│ │ behavior, environment; SAY statement;              │ │
│*│ │ MARK command; failure mode; behavior, failsafe     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and 2.                            │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 16 traces in less than 1 sec.             │ │
│*│ │ Scope 2: 36 traces in approx. 29 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
