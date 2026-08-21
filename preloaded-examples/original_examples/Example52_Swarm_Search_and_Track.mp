/*
Michael Revill
22 February 2016
Incorporating Failure Modes and Failsafe Behaviors
MP model Swarm_Search_and_Track elaborates on 
"Perform_Mission" event in Swarm2-v8.mp

Edited by K.Giamamrco on 26 Feb 2016
Established naming convention:
Noun-oriented events are actors  (root events)
Verb-oriented events in sentence case are activities 
Verb-oriented events in title case are states

This model demonstrates the found unexpected behavior for 
object discovery after bingo fuel (trace 6)

*/

SCHEMA Swarm_Search_and_Track

ROOT 	Swarm_Operator:	Command_swarm_to_commence_mission
   						Monitor_mission
   						Issue_recovery_command;

	Monitor_mission:	(*	Receive_target_alert
    						Assess_detected_object 
    						( Object_is_Valid_Target | 
                                Object_is_Not_Target )
						*);

ROOT 	Swarm: {+ UAV +};
     
	UAV: 	Commence_mission
          	Search_and_track_objects
          	Return_to_base
		  	End_mission;

	Search_and_track_objects:	
			
			(*	( 	Detect_object 
    				Evaluate_object 
      				( Target_Found 
                      Alert_operator 
                      Track_target 		| 
                                            
                          Non_Target_Found 
                          Resume_target_search ) 	|
    							
        					Bingo_Fuel 
        					Reassess_environment 
      						[ ( Target_Found 
                                Alert_operator 
                                Track_target 		| 
                                
                                Non_Target_Found 	
                               ) ]
  													
                )
			*); 

COORDINATE 	$a: Command_swarm_to_commence_mission	FROM Swarm_Operator 
	DO	COORDINATE $b: Commence_mission				FROM Swarm 
 				DO ADD $a PRECEDES $b; OD;
	OD;	

COORDINATE 	$a: Alert_operator			FROM Swarm,
			$b: Receive_target_alert	FROM Swarm_Operator 
 	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Issue_recovery_command		FROM Swarm_Operator 
	DO	 COORDINATE $b: Return_to_base		FROM Swarm 
 			DO ADD $a PRECEDES $b; OD;
 	OD;		

ROOT Environment: (* Present_object_signature *);

COORDINATE 	$a: Present_object_signature 	FROM Environment, 
			$b: Detect_object				FROM Swarm
	DO ADD $a PRECEDES $b; OD;
