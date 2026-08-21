/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Manufacturing Process                     │ │
│*│ │  Created by John Palmer in August, 2014.           │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │ 
│*│ │  Edited by Kristin Giammarco in January, 2022 to   │ │
│*│ │  	add cost attributes and local and global cost    │ │ 
│*│ │   calculations.                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate a cost analysis in a model of a     │ │ 
│*│ │ system manufacturing process.                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates a cost analysis application│ │ 
│*│ │ of Monterey Phoenix modeling to a manufacturing    │ │ 
│*│ │ process. This model was originally composed using  │ │ 
│*│ │ Eagle6, a prototype MP user interface. Eagle6 did  │ │ 
│*│ │ not implement COORDINATE statements, probabilities,│ │ 
│*│ │ or event attributes so the original model used     │ │
│*│ │ SHARE ALL to simulate COORDINATE and performed cost│ │ 
│*│ │ calculations externally. The 2014 model was        │ │
│*│ │ implemented in MP version 4 to demonstrate         │ │ 
│*│ │ integration of cost analysis capability in MP.     │ │ 
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Palmer, John. "Utilization of Monterey Phoenix     │ │ 
│*│ │ Modeling to Expedite Cost Estimation in            │ │ 
│*│ │ Manufacturing Systems." Stevens Institute of       │ │ 
│*│ │ Technology Master's Project, September 2014.       │ │                                     
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, manufacturing process; analysis, cost;   │ │ 
│*│ │ report, local; report, global                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Manufacturing_System

ROOT SYSTEM:	Incoming_Material
				Multi_Axis_Machine
				Media_Finish
				Send_to_Inspector
    
				[ 	Rejected
					Rework
					Send_to_Inspector 
				]
    
				Accepted

				( Turning_Machine_1 
                  Milling_Machine_1 
                  Turning_Machine_2 
                  Milling_Machine_2  		| 
                  
                  <<0.7>>  	Multitask_1 
                    		Multitask_2 	)
    
				Send_to_Inspector2
    
				[ 	Rejected2
					Rework2
					Send_to_Inspector2
				]
    
				Accepted2

				Surface_Treatment
				Package_Part
				Ship_Part
;
						
ROOT INSPECTOR:  (* <0..2> 	Inspect 
    						( Accept | <<0.2>> Reject ) 
    			  *);
					
		Inspect: CheckPart ProvideAnswer;	


COORDINATE	$x: Send_to_Inspector	FROM SYSTEM, 
			$y: Inspect FROM INSPECTOR
	DO ADD $x PRECEDES $y; OD;

COORDINATE	$x: Accept	FROM INSPECTOR, 
			$y: Accepted FROM SYSTEM
	DO ADD $x PRECEDES $y; OD;

COORDINATE	$x: Reject	FROM INSPECTOR, 
			$y: Rejected FROM SYSTEM
	DO ADD $x PRECEDES $y; OD;


ROOT INSPECTOR2: (* <0..2> 	Inspect2
							( Accept2 | <<0.1>> Reject2 ) 
				  *);
					
		Inspect2: CheckPart2 ProvideAnswer2;	


COORDINATE	$x: Send_to_Inspector2	FROM SYSTEM, 
			$y: Inspect2 FROM INSPECTOR2
	DO ADD $x PRECEDES $y; OD;

COORDINATE	$x: Accept2	FROM INSPECTOR2, 
			$y: Accepted2 FROM SYSTEM
	DO ADD $x PRECEDES $y; OD;

COORDINATE	$x: Reject2	FROM INSPECTOR2, 
			$y: Rejected2 FROM SYSTEM
	DO ADD $x PRECEDES $y; OD;


/* ------- Add duration and cost attributes (hours) ------- */

ATTRIBUTES{	number 	cost, trace_cost, weighted_cost, 
    				accumulated_max_cost, accumulated_min_cost,
    				accumulated_costs,
    				trace_unique_id,
    				largest_cost_trace_id, smallest_cost_trace_id, 
    				trace_time;
			bool	c_max, c_min;};


COORDINATE $e: Incoming_Material 	DO 	SET	$e.duration AT LEAST 2;
    										$e.cost:= 65;			OD;

COORDINATE $e: Multi_Axis_Machine 	DO 	SET $e.duration AT LEAST 12;
    										$e.cost:= 225;			OD;

COORDINATE $e: Media_Finish 		DO 	SET $e.duration AT LEAST 7;
    										$e.cost:= 110;			OD;

COORDINATE $e: Send_to_Inspector 	DO 	SET $e.duration AT LEAST 0.5;
    										$e.cost:= 65;			OD;

COORDINATE $e: Accepted 			DO 	SET $e.duration AT LEAST 2;
    										$e.cost:= 125;			OD;

COORDINATE $e: Multitask_1 			DO 	SET $e.duration AT LEAST 8;
    										$e.cost:= 195;			OD;

COORDINATE $e: Multitask_2 			DO 	SET $e.duration AT LEAST 8;
                                            $e.cost:= 195;			OD;

COORDINATE $e: Send_to_Inspector2 	DO 	SET $e.duration AT LEAST 0.5;
    										$e.cost:= 65;			OD;

COORDINATE $e: Accepted2 			DO 	SET $e.duration AT LEAST 2;
    										$e.cost:= 125;			OD;

COORDINATE $e: Surface_Treatment 	DO 	SET $e.duration AT LEAST 7;
                                            $e.cost:= 145;			OD;

COORDINATE $e: Package_Part 		DO 	SET $e.duration AT LEAST 0.5;
    										$e.cost:= 45;			OD;

COORDINATE $e: Ship_Part 			DO 	SET $e.duration AT LEAST 1.5;
    										$e.cost:= 95;			OD;

COORDINATE $e: Milling_Machine_1 	DO 	SET $e.duration AT LEAST 6;
    										$e.cost:= 165;			OD;

COORDINATE $e: Milling_Machine_2 	DO 	SET $e.duration AT LEAST 6;
    										$e.cost:= 165;			OD;

COORDINATE $e: Rejected 			DO 	SET $e.duration AT LEAST 2.5;
                                            $e.cost:= 125;			OD;

COORDINATE $e: Rejected2 			DO 	SET $e.duration AT LEAST 2.5;
                                            $e.cost:= 125;			OD;

COORDINATE $e: Rework 				DO 	SET $e.duration AT LEAST 8;
    										$e.cost:= 150;			OD;	

COORDINATE $e: Rework2 				DO 	SET $e.duration AT LEAST 8;
    										$e.cost:= 150;			OD;

COORDINATE $e: Turning_Machine_1 	DO 	SET $e.duration AT LEAST 6;
    										$e.cost:= 170;			OD;

COORDINATE $e: Turning_Machine_2 	DO 	SET $e.duration AT LEAST 6;
    										$e.cost:= 170;			OD;

/* Comment in below statement to print the individual event costs */
/*COORDINATE $e: $$EVENT 
	DO	ADD $e has_cost SAY ("$" $e.cost ); OD;*/

/* Create table of action rates and times */

TABLE Trace_cost_and_time_table { TITLE("Action Rates and Time Required");
	TABS 	string Event,
    		number Action_Rate_dollars,
    		number Cycle_Time_hours,
    		number Action_Cost_dollars;
};
	
	CLEAR Trace_cost_and_time_table;
    		

	COORDINATE $e: $$EVENT 	
		DO					
			IF $e.cost > 0 AND $e.duration.largest > 0 THEN
					Trace_cost_and_time_table <| 
							Event: 					SAY($e),
							Action_Rate_dollars: 	$e.cost,
							Cycle_Time_hours: 		$e.duration.largest,
							Action_Cost_dollars: 	$e.cost * $e.duration.largest;

							trace_cost+:= ($e.cost*$e.duration.largest);
							trace_time+:= ($e.duration.largest);
			FI;
		OD;

/*  Find the highest-cost trace */
IF	GLOBAL.accumulated_max_cost < THIS.trace_cost THEN 
	GLOBAL.accumulated_max_cost:= THIS.trace_cost;
	GLOBAL.largest_cost_trace_id := trace_id;
FI;

/*  Find the lowest-cost trace  */
IF 	GLOBAL.accumulated_min_cost >= THIS.trace_cost OR 
	GLOBAL.accumulated_min_cost == 0 
	THEN 
	GLOBAL.accumulated_min_cost:= THIS.trace_cost; 
	GLOBAL.smallest_cost_trace_id := trace_id;
FI;

/* 	Find the total of all trace costs for the denominator of 
	the average cost calculation */
GLOBAL.accumulated_costs +:= THIS.trace_cost;

/*  Store trace duration data in a graph container for later 
	accessing by GLOBAL section */
GRAPH trace_data { };

WITHIN trace_data{ 
				Node$x: NEW(trace_cost);
				Node$x.trace_unique_id := trace_id;
    			Node$x.trace_cost := THIS.trace_cost;
				}; 

/* Annotate each trace with table and SAY statements */
SHOW Trace_cost_and_time_table;
SAY("Trace Cost: $"trace_cost);
SAY("Trace Time: "trace_time" hours");

/* Create and print global reports */
GLOBAL 

/* Create table summarizing trace data */
TABLE trace_data_summary {
TABS number     Trace_Number,
     number     Trace_Probability,
     string     Trace_Cost,
     number		Weighted_Cost,
     string		Maximum_Cost,
     string 	Minimum_Cost; };

WITHIN trace_data{
    FOR Node$x
        DO 
    	weighted_cost +:= Node$x.trace_cost * #$$TP(Node$x.trace_unique_id);
    	IF Node$x.trace_cost == accumulated_max_cost
    		THEN c_max:= true; 
    		ELSE c_max:= false; FI;
    	IF Node$x.trace_cost == accumulated_min_cost
    		THEN c_min:= true; 
    		ELSE c_min:= false; FI;
    	trace_data_summary     <| 
                 Trace_Number:     	Node$x.trace_unique_id,
                 Trace_Probability: #$$TP(Node$x.trace_unique_id),
    			 Trace_Cost: 		SAY( "$"Node$x ),
    			 Weighted_Cost:		weighted_cost,
    			 Maximum_Cost:		SAY ( c_max ),
    			 Minimum_Cost:		SAY ( c_min );                                               
        OD;
};

SHOW trace_data_summary;

/*Create summary report */

REPORT Summary_Statistics_Report { 
    TITLE ("Scope "$$scope" Summary Statistics"); };

SAY("There are " #$$TRACE " traces total." )
	=> Summary_Statistics_Report;

SAY ("Average cost assuming equal trace probabilities is: $" 
    accumulated_costs/#$$TRACE"." )
	=> Summary_Statistics_Report;

SAY ("Expected cost based on assigned trace probabilities is: $" 
    weighted_cost"." )
	=> Summary_Statistics_Report;

SAY("Trace "largest_cost_trace_id " has a max cost of $" 
    accumulated_max_cost"." ) 
	=> Summary_Statistics_Report;

SAY("Trace "smallest_cost_trace_id " has a min cost of $" 
    accumulated_min_cost"." )
	=> Summary_Statistics_Report;

SHOW Summary_Statistics_Report;
SHOW ACTIVITY DIAGRAM SYSTEM;
