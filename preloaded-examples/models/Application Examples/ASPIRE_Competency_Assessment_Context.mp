/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of ASPIRE Competency Assessment System       │ │
│*│ │  Created by Madeline May and Matt Trice in July 2022.│ 
│*│ │  Expanded by Kristin Giammarco in September 2022.  │ │
│*│ │  Gantt chart event sorting modified by Pamela Dyer │ │
│*│ │    in June, 2024.                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show the fundamental goal of the VA NAII All    │ │
│*│ │ Services Personnel and Institutional Readiness     │ │ 
│*│ │ Engine (ASPIRE), which is to assess the AI         │ │ 
│*│ │ competencies of current and would-be personnel     │ │  
│*│ │ across governmental organizations to allow for     │ │ 
│*│ │ more efficient, effective, and secure operations.  │ │ 
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using MP to model the      │ │ 
│*│ │ ASPIRE assessment system, which will employ a novel│ │ 
│*│ │ common data model (CDM). The model accounts        │ │
│*│ │ for interactions among employees, the ASPIRE system│ │ 
│*│ │ and supervisors. In general, the goal of the model │ │ 
│*│ │ is to ensure that the correct competency assessment│ │ 
│*│ │ is made, the human-AI interaction is smooth, and   │ │ 
│*│ │ the upskilling occurs completely and efficiently.  │ │ 
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ M. Trice and M. May, "ASPIRE Competency Assessment," │
│*│ │ MPVIP Cohort 4 Showcase Presentation, Department of│ │
│*│ │ Veterans Affairs, National Artificial Intelligence │ │
│*│ │ Institute, Washington, DC, USA, Summer 2022.       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, ASPIRE system; coordination, event;      │ │
│*│ │ coordination, conditional; ENSURE condition;       │ │
│*│ │ SAY statement; trace annotation; graph, bar chart; │ │
│*│ │ graph, Gantt chart; statistics, assembling;        │ │
│*│ │ event attribute, number; probability, interval;    │ │
│*│ │ table; graph, histogram; report, global;           │ │
│*│ │ graph, activity diagram; graph, flowchart;         │ │
│*│ │ UML diagram, activity; SysML diagram, activity     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2 and 3 to see traces involving  │ │
│*│ │  1, 2, or 3 employees, respectively.               │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 7 traces in  2.77 sec.                    │ │
│*│ │ Scope 3: 12 traces in approx. 123 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │   
└*┴───────────────────────────────────────────────────────*/


SCHEMA Existence_of_Competency

ROOT Employees: {+ Employee +};

 Employee: 	enroll_in_ASPIRE
			take_AI_Test
    		[ 	receive_learning_pathway
				complete_learning_pathway 	]
;


ROOT ASPIRE: 	{+ 	make_employee_file
			 		add_employee_file_to_database
			 		furnish_AI_competency_test
			 		update_file 					+}
 		 		{+ check_database +}
;

	check_database: ( 	<<0.3>> employee_in_team_has_knowledge 				| 
    	    			<<0.2>> NO_team_or_outside_employee_has_knowledge 	|
    					<<0.5>> outside_employee_has_knowledge				)

					send_personnel_report
					[ 	create_learning_pathway
						furnish_learning_pathway
						update_employee_file
						send_updated_report 		]
	; 

ROOT Supervisor:	identify_tasked_demand
    			 	query_ASPIRE_about_competency    			
				 	receive_report
				 	[ ( 	directs_internal_employee_upskilling
							receive_updated_report 					|
                    
					 	push_transfer 								)  ]

					 meet_demand_fill_team_gap
;

COORDINATE $x: enroll_in_ASPIRE, $y: make_employee_file
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: query_ASPIRE_about_competency
	DO COORDINATE $y: check_database
		DO ADD $x PRECEDES $y; OD;
	OD;

COORDINATE $x: furnish_AI_competency_test, $y: take_AI_Test
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: take_AI_Test, $y: update_file
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: send_personnel_report, $y: receive_report
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: NO_team_or_outside_employee_has_knowledge, $y: create_learning_pathway
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: furnish_learning_pathway, $y: receive_learning_pathway
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: complete_learning_pathway, $y: update_employee_file
	DO ADD $x PRECEDES $y; OD;

IF #NO_team_or_outside_employee_has_knowledge == 1 THEN
	COORDINATE $x: directs_internal_employee_upskilling, $y: create_learning_pathway
		DO ADD $x PRECEDES $y; OD;
FI;

COORDINATE $x: send_updated_report, $y: receive_updated_report
	DO ADD $x PRECEDES $y; OD;

IF #outside_employee_has_knowledge == 1 THEN
	COORDINATE $x: receive_report, $y: push_transfer
		DO ADD $x PRECEDES $y; OD;
FI;


/*We only push a transfer in the case where an outside employee has knowledge*/
ENSURE #push_transfer == 1 <-> #outside_employee_has_knowledge == 1;


IF #employee_in_team_has_knowledge > 0 THEN
	SAY ("competency is found within the team"); 
FI;

IF #outside_employee_has_knowledge > 0 THEN
	SAY ("competency is found in employee outside team"); 
FI;

IF #NO_team_or_outside_employee_has_knowledge > 0 THEN
	SAY ("No employee has competency and upskilling through ASPIRE required"); 
FI;


/* event durations (hours) */

COORDINATE 	$a: enroll_in_ASPIRE 							DO SET $a.duration  AT LEAST 0.34; OD;
COORDINATE 	$a: make_employee_file 							DO SET $a.duration  AT LEAST 0.001; OD;
COORDINATE 	$a: add_employee_file_to_database 				DO SET $a.duration  AT LEAST 0.001; OD;
COORDINATE 	$a: furnish_AI_competency_test 					DO SET $a.duration  AT LEAST 0.001; OD;
COORDINATE 	$a: take_AI_Test 								DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: update_file 								DO SET $a.duration  AT LEAST 0.001; OD;

COORDINATE 	$a: identify_tasked_demand 						DO SET $a.duration  AT LEAST 2; OD;
COORDINATE 	$a: query_ASPIRE_about_competency 				DO SET $a.duration  AT LEAST 0.25; OD;

COORDINATE 	$a: send_personnel_report 						DO SET $a.duration  AT LEAST 0.01; OD;
COORDINATE 	$a: send_updated_report 						DO SET $a.duration  AT LEAST 0.01; OD;

COORDINATE 	$a: receive_report 								DO SET $a.duration  AT LEAST 0.25; OD;
COORDINATE 	$a: receive_updated_report 						DO SET $a.duration  AT LEAST 0.25; OD;

COORDINATE 	$a: directs_internal_employee_upskilling 		DO SET $a.duration  AT LEAST 0.25; OD;
COORDINATE 	$a: create_learning_pathway 					DO SET $a.duration  AT LEAST 0.01; OD;
COORDINATE 	$a: receive_learning_pathway 					DO SET $a.duration  AT LEAST 1; OD;
COORDINATE 	$a: furnish_learning_pathway 					DO SET $a.duration  AT LEAST 0.001; OD;
COORDINATE 	$a: complete_learning_pathway 					DO SET $a.duration  AT LEAST 40; OD;
COORDINATE 	$a: update_employee_file 						DO SET $a.duration  AT LEAST 0.001; OD;

COORDINATE 	$a: meet_demand_fill_team_gap 					DO SET $a.duration  AT LEAST 0.25; OD;
COORDINATE 	$a: push_transfer 								DO SET $a.duration  AT LEAST 200; OD;

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
                 Trace_Number:     		SAY( Node$x.trace_unique_id ),
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

SHOW ACTIVITY DIAGRAM Employees, Employee, ASPIRE, Supervisor;
