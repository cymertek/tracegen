/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of a Ballistic Missile Defense System        │ │
│*│ │  Created by Alexander Nguyen on the 12th of        │ │
│*│ │     September, 2022.                               │ │
│*│ │  Edited by Kristin Giammarco in Sept and Oct, 2022.│ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To introduce beginners to the MP behavior modeling │ │
│*│ │ language and tool.                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model provides an orientation for those just  │ │
│*│ │ getting started using MP-Firebird. All events and  │ │
│*│ │ event attributes in this model are notional for the│ │
│*│ │ sole purpose of demonstrate the computational      │ │
│*│ │ modeling capabilities of MP. The text editor pane  │ │
│*│ │ allows one to compose  and edit code in the high-  | │
│*│ │ level MP language. Press the Run button to generate│ │
│*│ │ event traces from the code, then inspect the       │ │
│*│ │ results in the center pane. Use the far right pane │ │
│*│ │ to navigate the resulting traces and the Global    │ │
│*│ │ View at the top of the trace thumbnails.  Use the  │ │
│*│ │ scope slider bar  next to the Run button to control│ │
│*│ │ the number of loop iterations.                     │ │             
│*│ │                                                    │ │
│*│ │ ROOT A: B C;  A is a root event that includes      │ │
│*│ │               events B followed by C               │ │
│*│ │ ( B | C )	    Alternative events B or C (but not   │ │
│*│ │               both together in the same trace)     │ │
│*│ │ (* B *)       iterate B zero or more times         │ │
│*│ │ [ B ]         B is optional                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Aegis BMD Stellar Minotaur (FTM-18) Flight Mission │ │
│*│ │ Success Quicklook.  https://youtu.be/tpX0EwO5SkE   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, missile defense; analysis, schedule;     │ │
│*│ │ probability, Type 1; SAY statement; report, global;│ │ 
│*│ │ table, global; graph, activity diagram; graph,     │ │
│*│ │ Gantt chart                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up. You may also make changes │ │
│*│ │ to this model and run it with your changes. Save   │ │
│*│ │ your model using the EXPORT button.                │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 18 traces in approx. 17 sec.              │ │
│*│ │ Scope 3: 117 traces in approx. 55 min.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA Ballistic_Missile_Defense

ROOT Target: (+ Take_off [ ( Hit | Missed ) ] +)
;

ROOT Radar: (+ Detect_target +)
;

COORDINATE $a: Take_off, $b: Detect_target
	DO ADD $a PRECEDES $b; OD;


ROOT Combat_System: (+	Establish_target_track
						Develop_firing_control_solution
						[ Provide_updated_target_information
					  	  ( Verify_successful_missile_interception 		| 
                        	Verify_unsuccessful_missile_interception 	) 
						]
    				 +)
;
 
ROOT Crew: 	(+ 	Request_launch_authorization
				( Initialize_launch | Scrub_launch )
				[ Command_missile_launch ] 	
    		 +)
;


COORDINATE $a: Detect_target, $b: Establish_target_track
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Develop_firing_control_solution, $b: Request_launch_authorization
	DO ADD $a PRECEDES $b; OD;

ROOT Captain: (+ ( <<0.96>> Authorize_missile_launch | Deny_missile_launch ) +)
;


COORDINATE $a: Request_launch_authorization, $b: ( Authorize_missile_launch | Deny_missile_launch )
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Authorize_missile_launch, $b: Initialize_launch
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Deny_missile_launch, $b: Scrub_launch
	DO ADD $a PRECEDES $b; OD;


ROOT Missile_Launching_System: (* Prepare_for_launch *)
;

COORDINATE $a: Initialize_launch, $b: Prepare_for_launch
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Prepare_for_launch, $b: Command_missile_launch
	DO ADD $a PRECEDES $b; OD;

ROOT Missile: (* Launch
				Maneuver_to_target
				( <<0.99>> Intercept_target | Miss_target ) *)
;

COORDINATE $a: Launch, $b: Provide_updated_target_information
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Launch, $b: Command_missile_launch
	DO ADD $b PRECEDES $a; OD;

COORDINATE $a: Provide_updated_target_information, $b: Maneuver_to_target
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Intercept_target, $b: Hit
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Miss_target, $b: Missed
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Hit, $b: Verify_successful_missile_interception
	DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Missed, $b: Verify_unsuccessful_missile_interception
	DO ADD $a PRECEDES $b; OD;




/* event durations (minutes) */

COORDINATE 	$a: Detect_target 						DO SET $a.duration  AT LEAST 1; OD;

COORDINATE 	$a: Establish_target_track 				DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Develop_firing_control_solution 	DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Provide_updated_target_information 	DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Request_launch_authorization 		DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Initialize_launch 					DO SET $a.duration  AT LEAST 1; OD;

COORDINATE 	$a: Command_missile_launch 				DO SET $a.duration  AT LEAST 1; OD;

COORDINATE 	$a: Authorize_missile_launch 			DO SET $a.duration  AT LEAST 1; OD;

COORDINATE 	$a: Deny_missile_launch 				DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Prepare_for_launch 					DO SET $a.duration  AT LEAST 1; OD;

COORDINATE 	$a: Launch 								DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: Maneuver_to_target 					DO SET $a.duration  AT LEAST 1; OD;

/* --------- Build Gantt Charts on traces --------- */

TABLE Gantt_Table{ 
	TABS 	string event_name, 
			number start_time, 
			number duration_time;
};
	CLEAR Gantt_Table;

BAR CHART Gantt_Chart { TITLE("Process Timeline (hours)");
	FROM Gantt_Table;
	X_AXIS event_name;
	ROTATE; 
};

COORDINATE <SORT> $event: $$ATOM
	DO 	
		IF $event.duration.largest > 0 THEN
			Gantt_Table 		<|
			event_name: 	SAY($event),
			start_time: 	$event.start.smallest,
			duration_time:  $event.duration.largest;
		FI;
	OD;

SHOW Gantt_Chart;

SAY("Trace " trace_id " Total Time: " THIS.duration " minutes");

/* ---- Accumulate data from traces for global reports ---- */

ATTRIBUTES {number 	accumulated_max_duration,
                    accumulated_min_duration,
    				accumulated_durations,
    				shortest_trace_id,
    				longest_trace_id,
    				trace_unique_id,
    				trace_duration,
    				weighted_duration,
    				count;
			bool 	d_max, d_min;
			};

/*  Find the longest trace */
IF 	GLOBAL.accumulated_max_duration < THIS.duration.largest THEN
	GLOBAL.accumulated_max_duration := THIS.duration.largest; 
	GLOBAL.longest_trace_id := trace_id;
FI;

/*  Find the shortest trace */
IF 	GLOBAL.accumulated_min_duration >= THIS.duration.smallest OR
	GLOBAL.accumulated_min_duration == 0	THEN
	GLOBAL.accumulated_min_duration := THIS.duration.smallest;
	GLOBAL.shortest_trace_id := trace_id;
FI;

/* 	Find the total of all trace durations for the denominator of 
	the average duration calculation */
GLOBAL.accumulated_durations +:= THIS.duration.smallest;

/*  Store trace duration data in a graph container for later 
	accessing by GLOBAL section */
GRAPH trace_data { };
WITHIN trace_data{ 
				Node$x: NEW(THIS.duration.smallest);
				Node$x.trace_unique_id := trace_id;
    			Node$x.trace_duration := THIS.duration.smallest;
				}; 

/* Create and print global reports */
GLOBAL

/* Create table summarizing trace data */

TABLE trace_data_summary {
TABS string     Trace_Number,
     string     Trace_Probability,
     string     Trace_Duration_minutes,
     number     Weighted_Duration,
     string		Maximum_Duration,
     string		Minimum_Duration; };

WITHIN trace_data{
    FOR Node$x
        DO 
    	weighted_duration +:= 
    		Node$x.trace_duration * #$$TP(Node$x.trace_unique_id);
    	IF Node$x.trace_duration == accumulated_max_duration 
    		THEN d_max:= true; 
    		ELSE d_max:= false; FI;
    	IF Node$x.trace_duration == accumulated_min_duration 
    		THEN d_min:= true; 
    		ELSE d_min:= false; FI;
    
    	trace_data_summary     <| 
                 Trace_Number:     			SAY( Node$x.trace_unique_id ),
                 Trace_Probability: 		SAY( #$$TP(Node$x.trace_unique_id) ),
    			 Trace_Duration_minutes: 	SAY( Node$x ),
    			 Weighted_Duration:			weighted_duration,
    			 Maximum_Duration:			SAY( d_max ),
    			 Minimum_Duration:			SAY( d_min );                                      
        OD;
};

/* This table shows that there are 2 maximums and 1 minimum. */
SHOW trace_data_summary;


/* Create summary report */

REPORT Duration_Statistics_Report {
    		TITLE ("Scope "$$scope" Duration Statistics"); };

SAY("There are " #$$TRACE " traces total." )
			=> Duration_Statistics_Report;

SAY ("Expected duration based on assigned trace probabilities is: "
    	weighted_duration" minutes." )
			=> Duration_Statistics_Report;

SAY("Trace "longest_trace_id " has a max duration of " 
    	accumulated_max_duration" minutes." ) 
			=> Duration_Statistics_Report;

SAY("Trace "shortest_trace_id " has a min duration of " 
    	accumulated_min_duration" minutes." )
			=> Duration_Statistics_Report;

SHOW Duration_Statistics_Report;

SHOW ACTIVITY DIAGRAM Combat_System, Crew, Missile;
