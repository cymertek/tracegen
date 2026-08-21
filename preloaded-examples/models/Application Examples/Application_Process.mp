/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Application Process                       │ │
│*│ │  Created by Mikhail Auguston in 2018.              │ │
│*│ │  Edited by Pamela Dyer in September, 2021.         │ │
│*│ │  Probabilities and timing attributes, reports,     │ │
│*│ │   tables, and charts added by Kristin Giammarco in │ │
│*│ │   January, 2022.                                   │ │
│*│ │  Gantt chart event sorting modified by Pamela Dyer │ │
│*│ │    in June, 2024.                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To provide a template for an application approval  │ │
│*│ │ process involving multiple levels of approval, and │ │
│*│ │ demonstrate an example of a schedule analysis that │ │
│*│ │ takes trace probability into account.              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ An applicant submits application and needs to get  │ │
│*│ │ it approved by the bureaucratic chain of two       │ │
│*│ │ officials. If the first official approves, the     │ │
│*│ │ application is forwarded to the second official.   │ │
│*│ │ The overall application is approved only after it  │ │
│*│ │ receives both approvals. Each official can         │ │
│*│ │ approve/reject the application or request it be    │ │
│*│ │ reworked and resubmitted. Rework and resubmit      │ │
│*│ │ events may be repeated several times. Each         │ │
│*│ │ rejection is final and cannot be followed by       │ │
│*│ │ rework and resubmit events. This model may be      │ │
│*│ │ adapted for many applications such as college      │ │
│*│ │ application, permit application, and work travel   │ │
│*│ │ authorization.                                     │ │
│*│ │                                                    │ │
│*│ │ See Example 38 in the MP manual for an example of  │ │
│*│ │ how to split this model into multiple models       │ │
│*│ │ focusing on different alternative branches.        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 38: Application process model" from       │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, application process; isomorphism;        │ │
│*│ │ analysis, schedule                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 21 traces in less than 1 sec.             | │
│*│ │ Scope 2: 273 traces in 4.6 sec.                    │ │
│*│ │ Scope 3: 2730 traces in 379 sec.                   │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Application_Process

ROOT Applicant:
		Prepare_application
		Submit_application
		(* 	Rework
			Submit_application *)
			( 	Application_is_Approved |
				Application_is_Rejected )
;

ROOT Official_1:
	(+ 	Receive_application_from_Applicant
	   	In_Queue_for_Review
	   	Review_application
		(	<<0.7>> Approve_and_forward_to_Official_2 		|
			<<0.29>> Request_rework 						|
			<<0.01>> Reject 								) 
     +)

/* The process stops if a rejection occurs */
	BUILD{ 	ENSURE #Reject <= 1;
			ENSURE FOREACH $r: Reject #$$EVENT AFTER $r == 0; }
;

    In_Queue_for_Review: ( 	<<0.05>> Available_to_do_work 	| 
        					<<0.75>> Busy_with_other_work 	| 
        					<<0.20>> Out_of_office 			);

COORDINATE 	$s: Submit_application 					FROM Applicant,
			$r: Receive_application_from_Applicant 	FROM Official_1
	DO ADD $s PRECEDES $r; OD;


ROOT Official_2:
	(* 	Receive_application_from_Official_1
	   	In_Queue_for_Review
	   	Review_application
		(	<<0.95>> Approve_and_forward_to_Applicant 		|
			<<0.04>> Request_rework 						| 
            <<0.01>> Reject 								) 
     *)

/* The process stops if a rejection occurs */
	BUILD{ 	ENSURE #Reject <= 1;	
			ENSURE FOREACH $r: Reject #$$EVENT AFTER $r == 0; }
;

COORDINATE 	$s: Approve_and_forward_to_Official_2 	FROM Official_1,
			$r: Receive_application_from_Official_1 FROM Official_2
	DO ADD $s PRECEDES $r; OD;

/* --------- Interactions with Applicant --------- */

COORDINATE 	$r: Reject, /* this may come from several actors */
			$rr: Application_is_Rejected FROM Applicant
	DO ADD $r PRECEDES $rr; OD;

COORDINATE 	$r: Request_rework, /* this may come from several actors */
			$rr: Rework FROM Applicant
	DO ADD $r PRECEDES $rr; OD;

COORDINATE 	$a: Approve_and_forward_to_Applicant 	FROM Official_2,
			$aa: Application_is_Approved 			FROM Applicant
	DO ADD $a PRECEDES $aa; OD;


/* ------- Add duration attributes (hours) ------- */

COORDINATE 	$a1: Prepare_application	DO SET $a1.duration  AT LEAST 8; 	OD;

COORDINATE  $a3: Rework 				DO SET $a3.duration  AT LEAST 1; 	OD;

COORDINATE 	$a4: Available_to_do_work 	FROM Official_1	
										DO SET $a4.duration  AT LEAST 0.5; 	OD;

COORDINATE 	$a4: Available_to_do_work 	FROM Official_2	
										DO SET $a4.duration  AT LEAST 1; 	OD;

COORDINATE 	$a4: Busy_with_other_work 	FROM Official_1
										DO SET $a4.duration  AT LEAST 24; 	OD;

COORDINATE 	$a4: Busy_with_other_work 	FROM Official_2	
										DO SET $a4.duration  AT LEAST 24; 	OD;

COORDINATE 	$a4: Out_of_office 			FROM Official_1	
										DO SET $a4.duration  AT LEAST 64; 	OD;

COORDINATE 	$a4: Out_of_office 			FROM Official_2	
										DO SET $a4.duration  AT LEAST 64; 	OD;

COORDINATE  $a5: Review_application 	FROM Official_1	
										DO SET $a5.duration  AT LEAST 0.25; OD;

COORDINATE  $a7: Review_application 	FROM Official_2 	
										DO SET $a7.duration  AT LEAST 0.03; OD;

/* --------- Build Gantt Charts on traces --------- */

TABLE Gantt_Table{ 
	TABS 	string event_name, 
			number start_time, 
			number duration_time;
};
	CLEAR Gantt_Table;

BAR CHART Gantt_Chart { TITLE("Application Process Timeline (hours)");
	FROM Gantt_Table;
	X_AXIS event_name;
	ROTATE; 
};

COORDINATE <SORT> $e: $$ATOM
	DO 	
		IF $e.duration.largest > 0 THEN
			Gantt_Table 		<|
			event_name: 	SAY($e),
			start_time: 	$e.start.smallest,
			duration_time:  $e.duration.largest;
		FI;
	OD;

SHOW Gantt_Chart;

SAY("Trace " trace_id " Total Time: " THIS.duration/8 " days");

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
     string     Trace_Duration_hours,
     number     Trace_Duration_days,
     number     Weighted_Duration_days,
     string		Maximum_Duration,
     string		Minimum_Duration; };

WITHIN trace_data{
    FOR Node$x
        DO 
    	weighted_duration +:= 
    		Node$x.trace_duration/8 * #$$TP(Node$x.trace_unique_id);
    	IF Node$x.trace_duration == accumulated_max_duration 
    		THEN d_max:= true; 
    		ELSE d_max:= false; FI;
    	IF Node$x.trace_duration == accumulated_min_duration 
    		THEN d_min:= true; 
    		ELSE d_min:= false; FI;
    
    	trace_data_summary     <| 
                 Trace_Number:     			SAY( Node$x.trace_unique_id ),
                 Trace_Probability: 		SAY( #$$TP(Node$x.trace_unique_id) ),
    			 Trace_Duration_hours: 		SAY( Node$x ),
        		 Trace_Duration_days: 		Node$x.trace_duration/8,
    			 Weighted_Duration_days:	weighted_duration,
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

SAY("Average duration assuming equal trace probabilities is: " 
    	accumulated_durations/8/#$$TRACE" days.")
			=> Duration_Statistics_Report;

SAY ("Expected duration based on assigned trace probabilities is: "
    	weighted_duration" days." )
			=> Duration_Statistics_Report;

SAY("Trace "longest_trace_id " has a max duration of " 
    	accumulated_max_duration/8" days." ) 
			=> Duration_Statistics_Report;

SAY("Trace "shortest_trace_id " has a min duration of " 
    	accumulated_min_duration/8" days." )
			=> Duration_Statistics_Report;

SHOW Duration_Statistics_Report;


/* Create probability histogram */

GRAPH trace_probability_histogram_data { };

WITHIN trace_probability_histogram_data{
    FOR Num$t: [1.. #$$TRACE] STEP 1 
        DO FOR Num$n: [0 .. 1] STEP 0.1
        	DO
            	Node$x: LAST("[" Num$n ".." Num$n + 0.1 ")");        
                	IF  ( Num$n <= #$$TP(Num$t) AND 
                          #$$TP(Num$t) < Num$n + 0.1) OR
                        ( #$$TRACE == 1 AND Num$n == 0.9 ) THEN 
                     Node$x.count +:= 1;
                    FI; 
            OD;
        OD;  
}; 


TABLE probability_histogram { TABS 	string     probability_interval,
        						 	number     trace_count; 
							};

BAR CHART probability_chart { TITLE("Trace Probabilities");
                              FROM		probability_histogram;
                              X_AXIS 	probability_interval; 
							};

WITHIN trace_probability_histogram_data {
    FOR Node$n
        DO probability_histogram     <| 
           		probability_interval:	SAY( Node$n ),
           		trace_count:          	Node$n.count;                                         
        OD;
};

SHOW probability_chart SORT;

SHOW ACTIVITY DIAGRAM Applicant, Official_1, Official_2;
