/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Correlation and Fusion Process with Data  │ │
│*│ │    Governance Framework                            │ │
│*│ │  Created by Frank Watson on the 20th of August,    │ │
│*│ │     2021.                                          │ │
│*│ │  Edited by Pamela Dyer in September, 2021.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To model AIS reporting data flows showing updated  │ │
│*│ │ data path behaviors with the application of a data │ │
│*│ │ governance framework.                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Models the data flow from sensors all the way to   │ │
│*│ │ the human analyst at a tactical location           │ │
│*│ │ incorporating a data governance framework. The     │ │
│*│ │ AIS_Sensor represents an example AIS GPS SENSOR;   │ │
│*│ │ the Aggregation_Service represents a local AIS     │ │
│*│ │ Aggregator like a Radar system or local AIS        │ │
│*│ │ Broadcast; the Global_Distribution_Mechanism       │ │
│*│ │ receives data from multiple aggregation services,  │ │
│*│ │ coalates the data, and rebroadcasts the data       │ │
│*│ │ globally. Within the                               │ │
│*│ │ Global_Distribution_Mechanism, Source A represents │ │
│*│ │ raw AIS tracks that have not been modified in any  │ │
│*│ │ way prior to dissemination; Source B represents    │ │
│*│ │ raw AIS tracks grouped into geographic areas for   │ │
│*│ │ limited broadcast; Source C represents custom      │ │
│*│ │ filtering and combining of AIS tracks based on     │ │
│*│ │ unique fields. The Data Governance Framework       │ │
│*│ │ applies an evaluation rubric to data sources and   │ │
│*│ │ only allows sources that are uncorrupted to be     │ │
│*│ │ transmitted to the correlator. The                 │ │
│*│ │ Data_Governance_Framework receives sources,        │ │
│*│ │ evaluates source corruption levels, applies a      │ │
│*│ │ rubric evaluation, and transmits approved sources  │ │
│*│ │ to the Correlator.                                 │ │
│*│ │                                                    │ │
│*│ │ The events are representative of actual AIS data   │ │
│*│ │ report flow to operational analysts, with the      │ │
│*│ │ insertion of a data governance framework.          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Watson, Frank. "Design Methodologies for 21st      │ │
│*│ │    Century Battlefield Object Correlation and      │ │
│*│ │    Fusion." NPS Master's Thesis, Monterey, CA:     │ │
│*│ │    September 2021.                                 │ │
│*│ │                                                    │ │
│*│ │ Watson, Frank. "Model of Correlation and Fusion    │ │
│*│ │    Process Ungoverned." 20 August 2021. In "Design │ │
│*│ │    Methodologies for 21st Century Battlefield      │ │
│*│ │    Object Correlation and Fusion." NPS Master's    │ │
│*│ │    Thesis, Monterey, CA: September 2021.           │ │
│*│ │                                                    │ │
│*│ │ Example 49. Histogram showing number of traces     │ │
│*│ │    with probabilities within certain intervals,    │ │
│*│ │    from Auguston, M. "Monterey Phoenix System and  │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Example 40. A global report is assembled from the  │ │
│*│ │    set of all available event traces, from         │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, data correlation and fusion;             │ │
│*│ │ probability, Type 1; data governance               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Correlation_and_Fusion_Process_with_Data_Governance
			 
ROOT    AIS_Sensor:		Send_Sensor_Data ;

ROOT    Aggregation_Service: 	Receive_Sensor_Data
    						 	Aggregate_Sensor_Data ;

ROOT	Global_Distribution_Mechanism:   Recieve_Multiple_Sources
    									 { Source_A, Source_B, Source_C }
										 Transmit_Tracks_To_Data_Governance_Framework ;

ROOT    Data_Governance_Framework: 	Receive_Sources 
    							  	{ Source_A, Source_B, Source_C }

									Evaluate_Source_Corruption_Level
   									Apply_Rubric_Evaluation
    								{ 	Evaluated_Source_A, 
                                        Evaluated_Source_B, 
                                        Evaluated_Source_C }	

                        			Transmit_Non_Corrupted_Report_Sources_To_Correlator ;


					Evaluated_Source_A: 	 (not_corrupted |<<0.01>> corrupted) ;
					Evaluated_Source_B: 	 (not_corrupted |<<0.01>> corrupted) ;

					/*Data Source C receives a "filtered" status from the data governance framework*/
                    Evaluated_Source_C:      filtered ;	


ROOT    Correlator: Receive_Source_Status 
     				{ Governed_Source_A, Governed_Source_B }
                    Process_Source_Status
                    Evaluate_Source_Status
                    Display_Correlated_Tracks ; 

ROOT	Analyst:  	View_Correlated_Tracks
					Analyze_Tracks_Position_Accuracy
					Correct_Track_Positions ;

/* Model the data flow to from sensor to the Analyst/Operator */
COORDINATE 	$x: Send_Sensor_Data 				FROM AIS_Sensor, 
			$y: Receive_Sensor_Data				FROM Aggregation_Service
	DO 	ADD $x PRECEDES $y; OD;

COORDINATE 	$x: Aggregate_Sensor_Data 			FROM Aggregation_Service, 
			$y: Recieve_Multiple_Sources		FROM Global_Distribution_Mechanism
	DO 	ADD $x PRECEDES $y; OD;

COORDINATE 	$x: Transmit_Tracks_To_Data_Governance_Framework	FROM Global_Distribution_Mechanism,
				$y: Receive_Sources	        					FROM Data_Governance_Framework
	DO 	ADD $x PRECEDES $y; OD;

COORDINATE 	$x: Transmit_Non_Corrupted_Report_Sources_To_Correlator	FROM Data_Governance_Framework,
				$y: Receive_Source_Status							FROM Correlator
	DO 	ADD $x PRECEDES $y; OD;

COORDINATE 	$x: Display_Correlated_Tracks				FROM Correlator,
				$y: View_Correlated_Tracks				FROM Analyst
	DO 	ADD $x PRECEDES $y; OD;

/* Establish a trace count/start the count */
ATTRIBUTES {number 	trace_unique_id, 
					summary_probability,
    				count; };

GRAPH good_traces{ }; /* To accumulate data about traces of interest */

/* Evaluate corrupted vs not_corrupted data traces percentage % = (A/B)*100%  */

    IF ((#corrupted /( #not_corrupted + #corrupted))*100)  == 0 THEN 
        WITHIN good_traces {
            Node$x: NEW(trace_id);
            Node$x.trace_unique_id := trace_id; };
        MARK; /* MARK the good trace with no data source corruption */

    FI; 

/* MARK traces in which all 3 sources are corrupt */

	IF #corrupted == 3 THEN MARK; 
	FI;

/* Display percentages of Good and Corrupted data sources on each trace */
    SAY ("Corrupted: " (#corrupted /( #not_corrupted + #corrupted))*100 "%");
    SAY ("Good: " (#not_corrupted /( #not_corrupted + #corrupted))*100 "%");


/* Create the global report */
GLOBAL

REPORT R{TITLE("Scope " $$scope);};

WITHIN good_traces{	FOR Node$x 	
                        DO
                            /* sum up probabilities of traces stored in the 'good_traces'. */
                            summary_probability +:= #$$TP(Node$x.trace_unique_id);
                        OD;
        		  };    

        SAY( "Total " #$$TRACE " traces") => R;
        SAY("TRACE ANALYSIS") => R; 
        SAY("Probability for all data sources to be Good in a trace at Scope "$$scope
            " is " (summary_probability*100)"%") => R;
        SAY("Probability for a Corrupted data source trace at Scope "$$scope
            " is " (100-(summary_probability*100))"%") => R;
SHOW R;


/* Create a probability histogram */

/* This graph is used as a container to collect data about valid trace probabilities */
GRAPH Data { };

/*Start of WITHIN Data */
	WITHIN Data{
            /* Numerical_loop_header(40) is used to perform required interval calculations. */ 
                FOR Num$t: [1.. #$$TRACE] STEP 1 
                    DO FOR Num$n: [0 .. 1] STEP 0.1
                      DO
                         Node$x: LAST("[" Num$n ".." Num$n + 0.1 ")");        
                         /*  p - pre-defined trace probability attribute */
                         IF  Num$n <= #$$TP(Num$t) AND 
                             #$$TP(Num$t) < Num$n + 0.1 THEN 
                             Node$x.count +:= 1;
                         FI; 
                      OD;
                    OD;  
				}; /* end of WITHIN Data */

/* Format Probabilty Chart */
TABLE probability_histogram {	TABS string     probability_interval,
         							 number     trace_count; 
							 };

BAR CHART probability_chart { TITLE("Trace probabilities");
                              FROM     probability_histogram;
                              X_AXIS probability_interval; 
							 };
        WITHIN Data{
                    FOR Node$n
                        DO probability_histogram     <| 
                                 probability_interval:     SAY(Node$n),
                                 trace_count:              Node$n.count;                                                     
                        OD;
       	 			};	

	SHOW probability_chart SORT;
/* The contents of the chart are sorted by X_AXIS string values*/

