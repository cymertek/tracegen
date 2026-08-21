/* Example8_OperationalProcess.mp
	modeling operational processes
	
Operational processes can be modeled to provide a common baseline against which 
alternative proposed solutions may be assessed.  

In this example, humans are conducting a wide area search in roles of Command and Control 
(C2), On Scene Commander (OSC), Person in Distress (PID), and Search And Rescue Assets 
(SAR Assets) apart from the OSC.
An actor called Physical Environment represents behaviors in the natural environment.

Actors may be partitioned and scoped according to the focus of the analysis.  The analysis
prompting this model calls for an analysis of alternatives for the On Scene Commander role
(e.g., manned helicopter, cutter, unmanned aerial/surface/underwater vehicles).

A System of Systems (SoS) analysis might expand the "SAR Asset" actor into distinct SAR assets
participating in or potentially participating in the scenario to study emergent behaviors of
those interacting systems in a SoS construct.

Run for scope 1 (there is no iteration in this example, so increaasing the scope will not 
produce more scenarios). Only one scenario is produced because no decision points have been 
added to this model yet.

The "Sequence" or "Swim Lanes" layouts are the most appropriate for browsing traces here. 
The "Sequence" mode yields views very similar to the UML or SysML Sequence Diagrams. 

*/


/* Actors */

SCHEMA Wide_Range_Search_for_Wreckage_and_Survivors

ROOT Command_and_Control:	Receive_distress_signal
							Pass_mission_information
               				Acknowledge_search_plan
							Receive_relayed_survivor_location_and_situation;

ROOT On_Scene_Commander:  	Receive_mission_information
               			Relay_mission_information
				Attempt_contact_with_PID
				Assess_environmental_conditions
				Receive_environmental_conditions
				Provide_search_plan
				Communicate_search_plan_and_responsibilities
				Scan_environment_for_signs_of_PID
				Receive_updates_for_OSC
				Receive_PID_location_and_situation
				Relay_survivor_location_and_situation;

ROOT PID:  			Send_distress_signal
				Identify_self_as_PID
				Present_for_rescue;

ROOT Physical_Environment:	Provide_environmental_conditions;

ROOT SAR_Assets:		Receive_relayed_mission_information
				Confirm_search_plan_and_responsibilities
				Scan_environment_for_signs_of_PID
				Provide_updates_to_OSC
				Spot_object_of_interest
				Maneuver_to_rescue_PID
				Notify_OSC_of_PID_location_and_situation;		

/* Interactions */

COORDINATE 	$a: Send_distress_signal	FROM PID,
			$b: Receive_distress_signal	FROM Command_and_Control
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Pass_mission_information	FROM Command_and_Control,
			$b: Receive_mission_information	FROM On_Scene_Commander
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Relay_mission_information  	    	FROM On_Scene_Commander,
			$b: Receive_relayed_mission_information FROM SAR_Assets
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Assess_environmental_conditions 	FROM On_Scene_Commander,
			$b: Provide_environmental_conditions 	FROM Physical_Environment
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Provide_environmental_conditions FROM Physical_Environment,
			$b: Receive_environmental_conditions FROM On_Scene_Commander
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Provide_search_plan  	FROM On_Scene_Commander,
			$b: Acknowledge_search_plan FROM Command_and_Control
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Acknowledge_search_plan  	             	 FROM Command_and_Control,
			$b: Communicate_search_plan_and_responsibilities FROM On_Scene_Commander
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Communicate_search_plan_and_responsibilities  FROM On_Scene_Commander,
			$b: Confirm_search_plan_and_responsibilities 	  FROM SAR_Assets
	DO ADD $a PRECEDES $b; OD;

On_Scene_Commander, SAR_Assets SHARE ALL Scan_environment_for_signs_of_PID;

COORDINATE 	$a: Provide_updates_to_OSC  FROM SAR_Assets,
			$b: Receive_updates_for_OSC FROM On_Scene_Commander
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Spot_object_of_interest  	FROM SAR_Assets,
			$b: Identify_self_as_PID		FROM PID
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Identify_self_as_PID  	FROM PID,
			$b: Maneuver_to_rescue_PID	FROM SAR_Assets
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Maneuver_to_rescue_PID  FROM SAR_Assets,
			$b: Present_for_rescue	    FROM PID
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Notify_OSC_of_PID_location_and_situation  	FROM SAR_Assets,
			$b: Receive_PID_location_and_situation			FROM On_Scene_Commander
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Relay_survivor_location_and_situation  	    	FROM On_Scene_Commander,
			$b: Receive_relayed_survivor_location_and_situation FROM Command_and_Control
	DO ADD $a PRECEDES $b; OD;
