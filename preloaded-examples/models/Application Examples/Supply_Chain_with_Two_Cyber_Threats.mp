/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Supply Chain with Two Cyber Threats       │ │
│*│ │  Based on the "Baseline Supply Chain" model        │ │
│*│ │  Created by Nathaniel Alden with help from Rachel  │ │
│*│ │     Talkington on the 5th of July, 2020.           │ │
│*│ │  Updated by Nathaniel Alden and Kristin Giammarco  │ │
│*│ │     on the 16th of December, 2020.                 │ │
│*│ │  Modified by Margaret Palmieri, added outcomes.    │ │
│*│ │  Modified by Margaret Palmieri, added risk and     │ │
│*│ │     probability.                                   │ │
│*│ │  Modified by Kristin Giammarco on the 14th of      │ │
│*│ │     January, 2021, regrouped attributes and added  │ │
│*│ │     global report.                                 │ │
│*│ │  Modified by Mikhail Auguston on the 14th of       │ │
│*│ │     January, 2021, added calculations to global    │ │
│*│ │     report.                                        │ │
│*│ │  Modified by Kristin Giammarco on the 25th of      │ │
│*│ │     February, 2021, cleaned up comments.           │ │
│*│ │  Modified by Margaret Palmieri on the 29th of      │ │
│*│ │     July, 2021, added Pipeline use case, updated   │ │
│*│ │     global report for two scenarios.               │ │
│*│ │  Modified by Kristin Giammarco on the 1st of       │ │
│*│ │     August, 2021, revised global report model for  │ │
│*│ │     two scenarios.                                 │ │
│*│ │  Modified by Margaret Palmieri on the 3rd of       │ │
│*│ │     August, 2021, updated attributes and model     │ │
│*│ │     notes.                                         │ │
│*│ │  Curated for model collection by Kristin Giammarco │ │
│*│ │     and Pamela Dyer on the 20th of September,      │ │
│*│ │     2021.                                          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the modeling of a supply chain that  │ │
│*│ │ is threatened by two separate cyber attacks, and   │ │
│*│ │ to demonstrate calculating individual and total    │ │
│*│ │ risk scores.                                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates performing detailed risk   │ │
│*│ │ analysis on a supply chain potentially affected by │ │
│*│ │ two cyber threats. This is made possible by        │ │
│*│ │ combining two MP models that each contained one    │ │
│*│ │ threat: a cyber attack on the barge, and a cyber   │ │
│*│ │ attack on the Colonial Pipeline. (All three of     │ │
│*│ │ these models can be found in Palmieri 2021).       │ │
│*│ │                                                    │ │
│*│ │ This model first takes advantage of separate       │ │
│*│ │ COORDINATE statements to calculate and display     │ │
│*│ │ risk associated with each use case individually,   │ │
│*│ │ and then performs calculations for the total risk  │ │
│*│ │ to the supply chain from both cyber threats.       │ │
│*│ │ Number attributes are used to determine both the   │ │
│*│ │ likelihood and impact factors for each case, and   │ │
│*│ │ then trace_risk_score combines them to generate    │ │
│*│ │ the total risk to the supply chain from both cyber │ │
│*│ │ threats. Each trace that is above a certain        │ │
│*│ │ threshold value is marked, and a global risk       │ │
│*│ │ report is issued. This report contains the total   │ │
│*│ │ risk across the total number of traces, highest    │ │
│*│ │ risk, average risk, and a direction to sort traces │ │
│*│ │ by those marked first. Decision makers can         │ │
│*│ │ reference models such as this when in need of      │ │
│*│ │ assessing and comparing risk across multiple       │ │
│*│ │ scenarios from multiple threats, especially when   │ │
│*│ │ it is necessary to best allocate limited resources │ │
│*│ │ for investing in cyber security.                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Palmieri, Margaret. "Assessing and Visualizing     │ │
│*│ │ Risk in Monterey Phoenix Through a Supply Chain    │ │
│*│ │ Cyber-Attack Use Case." NPS Master's Thesis,       │ │
│*│ │ Monterey, CA: September 2021.                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, supply chain; coordination, event;       │ │
│*│ │ cyber threat; cyber-attack;                        │ │
│*│ │ event attribute, number; table; trace annotation;  │ │
│*│ │ risk score; analysis, risk; SAY statement;         │ │
│*│ │ MARK command; report, global                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 12 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Supply_Chain_with_Two_Cyber_Threats


ROOT Cyber_Threat1:	
		( hacks_the_pressure_control_of_the_Colonial_Pipeline |
		  do_nothing )
;

ROOT Colonial_Pipeline:
    	receive_jet_fuel
    	send_fuel_through_pipeline
    	[ 	pipeline_bursts
        	fuel_is_halted
        	(	repair_light_damage 	|
            	repair_medium_damage 	|
            	repair_heavy_damage
            )
        	resend_fuel_through_pipeline
    	]
    	arrives_at_end_point
;


COORDINATE	$x: hacks_the_pressure_control_of_the_Colonial_Pipeline 
				FROM Cyber_Threat1,
            $y: pipeline_bursts 
				FROM Colonial_Pipeline
    DO ADD $x PRECEDES $y; OD;


ROOT DFSP_Baltimore:	
		receive_jet_fuel
    	tranform_jet_fuel_into_F24_jet_fuel
    	put_into_storage_tanks
    	load_onto_barge
		send_barge_to_DFSP_Anacostia
;

COORDINATE	$x: arrives_at_end_point	FROM Colonial_Pipeline,
            $y: receive_jet_fuel 		FROM DFSP_Baltimore
    DO ADD $x PRECEDES $y; OD;


ROOT Barge:	
		leaves_for_DSFP_Anacostia
		( 	navigation_systems_are_hacked
        	( 	barge_delayed arrives_at_DSFP_Anacostia		|
                
            	barge_sunk 									) 	|

                	arrives_at_DSFP_Anacostia 					)
;

ROOT Cyber_Threat2:	
		(	hacks_the_barge
        	( 	tries_to_delay_the_barge 	|
                
                tries_to_sink_the_barge		)	|
    				
            			no_impact				)
;

COORDINATE	$x: send_barge_to_DFSP_Anacostia    FROM DFSP_Baltimore,
            $y: leaves_for_DSFP_Anacostia 		FROM Barge
    DO ADD $x PRECEDES $y; OD;

COORDINATE  $x: hacks_the_barge     			FROM Cyber_Threat2,
           	$y: navigation_systems_are_hacked 	FROM Barge
   	DO ADD $x PRECEDES $y; OD;

COORDINATE  $x: tries_to_delay_the_barge     	FROM Cyber_Threat2,
           	$y: barge_delayed 					FROM Barge
   	DO ADD $x PRECEDES $y; OD;
	
COORDINATE  $x: tries_to_sink_the_barge     	FROM Cyber_Threat2,
           	$y: barge_sunk 						FROM Barge
   	DO ADD $x PRECEDES $y; OD;

/**/
/*	Remaining nodes to complete the supply chain commented out for 
	simplicity. Activate the following commented out code to see 
    entire supply chain.*/
/*

ROOT  DFSP_Anacostia:
    receive_F24_jet_fuel
    check_quality_and_amount
    send_to_Joint_Base_Andrews
    ;

COORDINATE    $x: arrives_at_DSFP_Anacostia 		FROM Barge,
              $y: receive_F24_jet_fuel 				FROM DFSP_Anacostia
    DO ADD $x PRECEDES $y; OD;

ROOT Joint_Base_Andrews:
    receive_F24_jet_fuel
	use_F24_jet_fuel
;

COORDINATE    $x: send_to_Joint_Base_Andrews     FROM DFSP_Anacostia,
              $y: receive_F24_jet_fuel FROM Joint_Base_Andrews
    DO ADD $x PRECEDES $y; OD;
*/

/**/

/* 	Event attributes include likelihood and impact to calculate a 
	trace_risk_score, risk, and other attributes used in global 
    risk report. Attribute sum_risk_score stores the sum of the 
    trace risk scores. */

ATTRIBUTES	{	number 	likelihood, impact, trace_risk_score, 
    					sum_risk_score, max_risk_score, 
    					max_risk_trace_unique_number;	
			};

/* Assigns attributes for the Colonial Pipeline use case */

COORDINATE $no_pipe_attack: do_nothing
	DO 	$no_pipe_attack.likelihood:= 0.2;
		$no_pipe_attack.impact:= 1; 
	OD;

COORDINATE $attack_bursts_pipeline: repair_light_damage 
	DO 	$attack_bursts_pipeline.likelihood:= 0.8;
		$attack_bursts_pipeline.impact:= 7; 
	OD;

COORDINATE $attack_bursts_pipeline: repair_medium_damage 
	DO 	$attack_bursts_pipeline.likelihood:= 0.8;
		$attack_bursts_pipeline.impact:= 9; 
	OD;

COORDINATE $repair_complete_6days: repair_heavy_damage
	DO 	$repair_complete_6days.likelihood:= 0.6;
		$repair_complete_6days.impact:= 9; 
	OD;

/* Assigns attributes for the Barge use case */

COORDINATE $no_barge_attack: no_impact 
	DO 	$no_barge_attack.likelihood:= 0.2;
		$no_barge_attack.impact:= 1; 
	OD;

COORDINATE $attack_to_delay: barge_delayed 
	DO 	$attack_to_delay.likelihood:= 0.8;
		$attack_to_delay.impact:= 5; 
	OD;

COORDINATE $attack_to_destroy: barge_sunk 
	DO 	$attack_to_destroy.likelihood:= 0.2;
		$attack_to_destroy.impact:= 5; 
	OD;


/* Trace Risk Table and Summary */

TABLE event_risks	{ 	TITLE ("Event Risks");
    					TABS 	string Event, 
								string Likelihood,
								string Impact,
    							string Risk_Score;
					};

CLEAR event_risks;

COORDINATE $e: $$EVENT
	
	DO 	trace_risk_score+:= ($e.likelihood*$e.impact);
		IF ($e.likelihood*$e.impact) > 0 THEN
				event_risks <|
					Event: SAY($e),
					Likelihood: SAY($e.likelihood),
					Impact: SAY($e.impact),
					Risk_Score: SAY($e.likelihood*$e.impact);
		FI;
	
		/*	If the TRACE RISK SCORE for a given trace exceeds the 
        	current global maximum risk factor value (initialized 
            at zero), then make the max risk factor THIS trace's 
            risk factor and get its trace id for the max risk trace. */
		IF  trace_risk_score > GLOBAL.max_risk_score THEN 
			GLOBAL.max_risk_score:= trace_risk_score;
			GLOBAL.max_risk_trace_unique_number:= trace_id;
		FI;

			/*MARK traces that have a risk factor greater than a certain value*/

			IF trace_risk_score >= 9 THEN MARK; FI;
	OD;

/* 	If there is a risk to the trace then show the risk table on the
	trace and say the totl trace risk. */
IF trace_risk_score > 0 THEN 	SHOW event_risks;
								SAY("Total Trace Risk: "trace_risk_score); 	
FI;


/**** Calculate Total Risk ****/

/* Sum up risk scores across all traces */
GLOBAL.sum_risk_score +:= trace_risk_score;
	

/* Create and display Global Risk Report */

GLOBAL

REPORT Global_Risk { TITLE ( "Risk Report for Scope " $$scope ); };

/* Include these SAY statements in the Global_Risk Report */
SAY("Total risk over " #$$TRACE " traces (sum of trace risk scores): " 
        						GLOBAL.sum_risk_score) 
								=> Global_Risk;
SAY("Highest Risk: " GLOBAL.max_risk_score" (trace " 
        						GLOBAL.max_risk_trace_unique_number")") 
								=> Global_Risk;
SAY("Average Risk: " GLOBAL.sum_risk_score/#$$TRACE) 
								=> Global_Risk;
SAY("Sort by Marked to view traces with above average risk >=9.") 
								=> Global_Risk; 

SHOW Global_Risk;
