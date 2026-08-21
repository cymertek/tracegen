/*******************************************************************

UAV HADR Mission

The following model specifies the ingress phase of the UAS HADR 
reference mission. The ingress phase is preceded by the preflight 
phase, and followed by the on-station phase.

This model contains an unexpected behavior in which the UAV status
is acceptable but the operator aborts the ingress (trace 2).
  
  created by A. Constable May 2017
  
********************************************************************/


SCHEMA UAV_Ingress

/*-----------------------
  JTF C2
-------------------------*/

ROOT JTF_C2:	Provide_launch_command; 


/*-----------------------
  GCS OPERATOR
-------------------------*/

ROOT GCS_Operator: 	(* Receive_launch_command
    				Check_launch_parameters_for_safety
    				Recieve_launch_clearence_from_host_ship
    				Provide_launch_command
    				Receive_UAV_status_and_position
    				Assess_UAV_status_and_position
    				Status_acceptable 
    				(Command_UAV_to_proceed_on_ingress 
                     Receive_UAV_position |
                        Command_UAV_abort)
    				*);


/*-----------------------
  GROUND CREW
-------------------------*/

ROOT Ground_Crew: 	(* Receive_launch_command
    				Provide_launch_command
    				*);


/*-----------------------
  UAV
-------------------------*/

ROOT UAV: 			(* Receive_launch_command
    				Launch
   					Execute_climb
    				Maneuver_to_clear_obstacles
    				Maneuver_to_ingress_altitude
    				Level_off_at_ingress_altitude
    				Transmit_status_and_position
    				(Receive_command_to_proceed 
                     Follow_flight_path_to_reach_onstation_area_and_altitude 
                     Reach_onstation_waypoint
                     Report_status |
                        Receive_command_to_abort
    					Abort_mission)
    				Apply_status_decision
    				*);


/*-----------------------
  NAV REFERENCE
-------------------------*/

ROOT Navigation_Reference:  ;



/*---------------------------------------------
  COORDINATION
-----------------------------------------------*/

COORDINATE 	$a: Provide_launch_command		FROM JTF_C2,
			$b: Receive_launch_command		FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Provide_launch_command		FROM GCS_Operator,
			$b: Receive_launch_command		FROM Ground_Crew
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Provide_launch_command		FROM Ground_Crew,
			$b: Receive_launch_command		FROM UAV
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Transmit_status_and_position		FROM UAV,
			$b: Receive_UAV_status_and_position		FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Command_UAV_to_proceed_on_ingress		FROM GCS_Operator,
			$b: Receive_command_to_proceed		FROM UAV
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Command_UAV_abort		FROM GCS_Operator,
			$b: Receive_command_to_abort		FROM UAV
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Report_status		FROM UAV,
			$b: Receive_UAV_position		FROM GCS_Operator
		DO ADD $a PRECEDES $b; OD; 



