/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Swarm Search and Track                    │ │
│*│ │  Created by Michael Revill on the 22nd of          │ │
│*│ │     February, 2016.                                │ │
│*│ │  Edited by Kristin Giammarco in February 2020,     │ │
│*│ │     added indentation only for readability.        │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate unexpected emergent behavior in an  │ │
│*│ │ unmanned aerial vehicle scenario involving a       │ │
│*│ │ low fuel condition.                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model was developed by an NPS student with    │ │
│*│ │ UAV operation experience with the intent to        │ │
│*│ │ illustrate the incorporation of failure modes and  │ │
│*│ │ corresponding failsafe behaviors into MP models of │ │
│*│ │ UAVs. The bingo fuel condition was modeled as an   │ │
│*│ │ optional event, in which case a UAV has just       │ │
│*│ │ enough fuel remaining to safely return to the      │ │
│*│ │ desired landing site. Among the traces produced    │ │
│*│ │ there is one particularly questionable scenario in │ │
│*│ │ which a UAV reached the bingo fuel condition and   │ │
│*│ │ then began to track a target. Several possible     │ │
│*│ │ requirements may be conceived as a result of this  │ │
│*│ │ finding, such as: “A UAV that has reached a bingo  │ │
│*│ │ fuel condition shall request permission from the   │ │
│*│ │ Swarm Operator to track any new targets found,” “A │ │
│*│ │ UAV that has found a possible target after         │ │
│*│ │ reaching bingo fuel shall relay the last known     │ │
│*│ │ location of the target to the Swarm Operator, then │ │
│*│ │ continue to return to base,” and “A UAV shall only │ │
│*│ │ track targets found before reaching bingo fuel     │ │
│*│ │ conditions.”                                       │ │
│*│ │                                                    │ │
│*│ │ This MP model elaborates on the "Perform_Mission"  │ │
│*│ │ event in the MP model "Swarm_UAV.mp" provided in   │ │
│*│ │ the Application examples folder of the preloaded   │ │
│*│ │ examples.                                          │ │
│*│ │                                                    │ │
│*│ │ Being a work in progress, this model is            │ │
│*│ │ incomplete, but this version of it was archived in │ │
│*│ │ order to capture the state of the model in which   │ │
│*│ │ the unexpected emergent behavior was first         │ │
│*│ │ observed.                                          │ │
│*│ │                                                    │ │
│*│ │ Established naming convention for events:          │ │
│*│ │ Noun-oriented events are actors (root events).     │ │
│*│ │ Verb-oriented events in sentence case are          │ │
│*│ │    activities.                                     │ │
│*│ │ Verb-oriented events in title case are states.     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Revill, Michael B. "UAV swarm behavior modeling    │ │
│*│ │    for early exposure of failure modes." Master's  │ │
│*│ │    Thesis, Naval Postgraduate School, September    │ │
│*│ │    2016. Available online:                         │ │
│*│ │    http://calhoun.nps.edu/handle/10945/50474       │ │
│*│ │                                                    │ │
│*│ │ Giammarco, Kristin, and Kathleen Giles.            │ │
│*│ │    "Verification and validation of behavior models │ │
│*│ │    using lightweight formal methods." In           │ │
│*│ │    Disciplinary convergence in systems engineering │ │
│*│ │    research, pp. 431-447. Springer, Cham, 2018.    │ │
│*│ │    Available online:                               │ │
│*│ │    https://calhoun.nps.edu/handle/10945/58237      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, swarm; behavior, search and track;       │ │
│*│ │ behavior, autonomous; behavior, environment;       │ │
│*│ │ failure modes; behavior, failsafe;                 │ │
│*│ │ behavior, unexpected                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1. A UAV may be part of a larger     │ │
│*│ │ swarm launched to search and track objects of      │ │
│*│ │ interest in the environment, but for the purposes  │ │
│*│ │ of this model running at scope 1 is sufficient to  │ │
│*│ │ see the unexpected behavior of object discovery    │ │
│*│ │ after bingo fuel (trace 6).                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
