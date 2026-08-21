/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Falcon 9 Launch to payload in orbit       │ │
│*│ │  MP model written by Frank Conenna Jr. and         │ │
│*│ │     Joe Novick for the spring 2021 SI 4022 class.  │ │
│*│ │     Professor: Dr. Kristin Giammarco.              │ │
│*│ │  Edited by Pamela Dyer in November, 2021.          │ │
│*│ │  Edited by Keane Reynolds in November, 2021.       │ │
│*│ │  Gantt chart event sorting modified by Pamela Dyer │ │
│*│ │    in June, 2024.                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate a launch of a SpaceX Falcon 9 rocket │ │
│*│ │ and first stage booster recover through system     │ │
│*│ │ behavior modeling.                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ A Falcon 9 Rocket is a two booster stage rocket    │ │
│*│ │ that is designed to carry payloads into space      │ │
│*│ │ cheaply. The Falcon 9 is able to launch payloads   │ │
│*│ │ cheaply by reusing the first stage booster.        │ │
│*│ │                                                    │ │
│*│ │ Prior to launch, the Falcon 9 Rocket is required   │ │
│*│ │ to complete pre launch checks which enables Flight │ │
│*│ │ Control to give a Go or No Go status for launch.   │ │
│*│ │ The rocket engines will ignite and the Falcon 9    │ │
│*│ │ Rocket will launch. At 148 seconds, the First      │ │
│*│ │ Stage Booster Separation occurs. The Second Stage  │ │
│*│ │ Ignites at 156 seconds. The Second stage continues │ │
│*│ │ into the upper atmosphere until the Fairing        │ │
│*│ │ Separates then the Payload Separates enabling the  │ │
│*│ │ Payload into Orbit.                                │ │
│*│ │                                                    │ │
│*│ │ The First Stage Booster Recovery is part of the    │ │
│*│ │ launch process but is separate from mission        │ │
│*│ │ success of getting a payload into orbit. The First │ │
│*│ │ Stage Booster Initiates Booster Sequence and       │ │
│*│ │ ignites the engines again for recovery and slows   │ │
│*│ │ down the booster for Earth reentry. Initiate       │ │
│*│ │ Booster Sequence occurs at 167 seconds and Flip    │ │
│*│ │ Booster occurs at 172 seconds. The Boostback Burn  │ │
│*│ │ occurs at 183 seconds. As the booster returns to   │ │
│*│ │ Earth, the booster Deploys Fins at 198 seconds and │ │
│*│ │ Aerodynamic Guidance at 200 seconds. Perform Entry │ │
│*│ │ Burn occurs at 467 seconds and to slow down the    │ │
│*│ │ booster for touchdown requires Perform Landing     │ │
│*│ │ Burn at 582 seconds.                               │ │
│*│ │                                                    │ │
│*│ │ Mission Success is not indicative of a successful  │ │
│*│ │ First Stage Booster Recovery. Mission Success is   │ │
│*│ │ only defined as successful payload launch into     │ │
│*│ │ orbit. Successful First Stage Booster recovery is  │ │
│*│ │ complete mission success and booster recovery      │ │
│*│ │ success.                                           │ │
│*│ │                                                    │ │
│*│ │ In summary, this model demonstrates the use of     │ │
│*│ │ COORDINATE statements to model the relationships   │ │
│*│ │ of a rocket launch, specifically SpaceX Falcon 9   │ │
│*│ │ launch events and makes those events easier to     │ │
│*│ │ understand using charts and "comments" from SAY    │ │
│*│ │ statements. Users can reference this model for     │ │
│*│ │ advice on COORDINATE statements and using MP to    │ │
│*│ │ add graphs and commentary to traces automatically. │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Giammarco, Kristin. "Monterey Phoenix Home."       │ │
│*│ │    Monterey Phoenix NPS Wiki. August 28, 2021.     │ │
│*│ │    https://wiki.nps.edu/display/MP                 │ │
│*│ │                                                    │ │
│*│ │ "MP Model Collection." Monterey Phoenix NPS        │ │
│*│ │    GitLab. November 2, 2021.                       │ │
│*│ │    https://gitlab.nps.edu/monterey-phoenix/mp-model-collection
│*│ │                                                    │ │
│*│ │ "Falcon User's Guide." Space Exploration           │ │
│*│ │    Technologies Corp. (SpaceX). September 2021.    │ │
│*│ │    https://www.spacex.com/media/falcon-users-guide-2021-09.pdf
│*│ │                                                    │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │    Architecture and Workflow Modeling Language     │ │
│*│ │    Manual" (Version 4). 2020. Available online:    │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, SpaceX; Falcon 9;                        │ │
│*│ │ event attribute, timing; trace annotation;         │ │
│*│ │ table; graph, Gantt chart; graph, bar chart        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 19 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Falcon_9_Launch

 

ROOT Flight_Control:	Go_Or_No_Go_Status
                    	( Go Initiate_Launch_Sequence 	| 
                      		No_Go Abort  				)
; 


Flight_Control SHARE ALL Go_Or_No_Go_Status, Go, No_Go;

 
ROOT Falcon_9_Rocket:	Pre_Launch_Checks
                   
                    	[ Ignite ( Launch | Ignition_Malfunction ) ]
;
                    
	Launch: /*First stage*/
			Second_Stage_Ignites 
			( First_Stage_Separation | First_Stage_Malfunction )
	;  

	First_Stage_Separation: ( Fairing_Separates | Fairing_sticks );
                    
	Fairing_Separates:	Payload_Separates Payload_Into_Orbit;

    Fairing_sticks: Mission_Failure;


Falcon_9_Rocket SHARE ALL Launch, Mission_Failure;


ROOT First_Stage_Booster_Recovery: [ Initiate_Booster_Sequence ];

	Initiate_Booster_Sequence:	(	Flip_Booster 						| 
        							No_Flip Recovery_Mission_Failure	);

    Flip_Booster: ( Boostback_Burn 							| 
        			No_Backburn Recovery_Mission_Failure 	);

	Boostback_Burn:	( 	Deploy_Fins 								| 
        				Burner_malfunction Recovery_Mission_Failure	);

    Deploy_Fins:	(	Perform_Entry_Burn 							| 
        				Fins_Do_Not_Deploy Recovery_Mission_Failure	);

    Perform_Entry_Burn: (	Aerodynamic_Guidance 						| 
        					Burner_malfunction Recovery_Mission_Failure	);

    Aerodynamic_Guidance:	( 	Perform_Landing_Burn 							| 
        						Guidance_malfunction Recovery_Mission_Failure	);

    Perform_Landing_Burn: (	Recovery_Success 							| 
        					Burner_malfunction Recovery_Mission_Failure	);


First_Stage_Booster_Recovery SHARE ALL 	Initiate_Booster_Sequence,
										Perform_Landing_Burn, 
										Recovery_Success;



COORDINATE $x: Pre_Launch_Checks  FROM Falcon_9_Rocket,
           $y: Go_Or_No_Go_Status FROM Flight_Control
         DO ADD $x PRECEDES $y; OD;

COORDINATE $x: Ignite                   FROM Falcon_9_Rocket,
           $y: Initiate_Launch_Sequence FROM Flight_Control
         DO ADD $y PRECEDES $x; OD;

COORDINATE $x: First_Stage_Separation      FROM Falcon_9_Rocket,
           $y: Initiate_Booster_Sequence   FROM First_Stage_Booster_Recovery
         DO ADD $x PRECEDES $y; OD;


/* Add duration attributes */

COORDINATE 	$a1: Launch              	      DO SET $a1.duration  AT LEAST 0;	 OD;
COORDINATE 	$a2: First_Stage_Separation       DO SET $a2.duration  AT LEAST 148; OD;
COORDINATE  $a3: First_Stage_Booster_Recovery DO SET $a3.duration  AT LEAST 593; OD;
COORDINATE 	$a4: Second_Stage_Ignites         DO SET $a4.duration  AT LEAST 156; OD;
COORDINATE  $a5: Initiate_Booster_Sequence    DO SET $a5.duration  AT LEAST 167; OD;
COORDINATE  $a6: Flip_Booster                 DO SET $a6.duration  AT LEAST 172; OD;
COORDINATE  $a7: Boostback_Burn               DO SET $a7.duration  AT LEAST 183; OD;
COORDINATE  $a8: Deploy_Fins                  DO SET $a8.duration  AT LEAST 198; OD;
COORDINATE  $a9: Aerodynamic_Guidance         DO SET $a9.duration  AT LEAST 200; OD;
COORDINATE  $a10: Perform_Entry_Burn          DO SET $a10.duration AT LEAST 467; OD;
COORDINATE  $a11: Perform_Landing_Burn        DO SET $a11.duration AT LEAST 582; OD;
COORDINATE  $a12: Recovery_Success            DO SET $a12.duration AT LEAST 593; OD;
COORDINATE 	$a13: Payload_Separates 	      DO SET $a13.duration AT LEAST 3390;OD;

/* Build trace tables and Gantt Charts */

TABLE gantt_1{ 
	TABS 	string event_name, 
			number start_time, 
			number duration_time;
};
	CLEAR gantt_1;

BAR CHART gantt_2 { TITLE("Falcon 9 Timeline (seconds)");
	FROM gantt_1;
	X_AXIS event_name;
	ROTATE; 
};

COORDINATE <SORT> $e: ( $$ATOM | $$COMPOSITE )
	DO 	
		gantt_1 		<|
			event_name: 	SAY($e),
			start_time: 	$e.start.smallest,
			duration_time:  $e.duration.largest;
	OD;

SHOW gantt_2;

SAY("Trace " trace_id " Total Time: " THIS.duration);

/* Build global reports */

ATTRIBUTES {number 	accumulated_max,
                    accumulated_min,
    				accumulated_durations,
    				smallest_trace_id,
    				longest_trace_id;	};

GLOBAL.accumulated_durations +:= THIS.duration.smallest;

IF GLOBAL.accumulated_max < THIS.duration.largest THEN
	GLOBAL.accumulated_max := THIS.duration.largest; 
	GLOBAL.longest_trace_id := trace_id;
FI;

IF GLOBAL.accumulated_min >= THIS.duration.smallest OR
	GLOBAL.accumulated_min == 0
	THEN
	GLOBAL.accumulated_min := THIS.duration.smallest;
	GLOBAL.smallest_trace_id := trace_id;
FI;

GLOBAL

REPORT Duration_Statistics_Report { TITLE ("Scope "$$scope" Duration Statistics");
									};
	CLEAR Duration_Statistics_Report;

SAY("There are " #$$TRACE " traces total." )
	=> Duration_Statistics_Report;
SAY("Trace "longest_trace_id " has the max duration of " accumulated_max"." ) 
	=> Duration_Statistics_Report;
SAY("Trace "smallest_trace_id " has the min duration of " accumulated_min"." )
	=> Duration_Statistics_Report;
SAY("The average duration across all traces is " accumulated_durations/#$$TRACE".")
	=> Duration_Statistics_Report;

SHOW Duration_Statistics_Report;
