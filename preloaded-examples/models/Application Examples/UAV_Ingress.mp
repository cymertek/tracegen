/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of UAV Ingress                               │ │
│*│ │  Created by Anthony Constable in May, 2017.        │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate unexpected emergent behavior in an  │ │
│*│ │ unmanned aerial vehicle (UAV) launch and ingress   │ │
│*│ │ scenario.                                          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model was developed by an NPS student to      │ │
│*│ │ specify the ingress phase of a UAV on a            │ │
│*│ │ Humanitarian Assistance / Disaster Relief (HADR)   │ │
│*│ │ reference mission described in Giammarco et al.    │ │
│*│ │ (2018). This model shows a nominal baseline        │ │
│*│ │ scenario (in which the status was found to be      │ │
│*│ │ acceptable and then the UAV was commanded to       │ │
│*│ │ proceed on ingress (trace 1)), and another         │ │
│*│ │ scenario in which the status was found to be       │ │
│*│ │ acceptable and then the UAV was commanded to abort │ │
│*│ │ ingress (trace 2). Several imagined future states  │ │
│*│ │ could explain the latter behavior in which ingress │ │
│*│ │ is aborted after a Status_acceptable event, such   │ │
│*│ │ as the operator receiving an indication from some  │ │
│*│ │ other source that the system is in trouble despite │ │
│*│ │ the system reporting all is well, or that the      │ │
│*│ │ mission suddenly changed and the UAV is no longer  │ │
│*│ │ needed. An example discovered requirement may be   │ │
│*│ │ "The UAV shall provide more than one means to      │ │
│*│ │ communicate its status and position."              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Giammarco, K; Carlson, C., Blackburn, M.           │ │
│*│ │ "Verification and Validation (V&V) of System       │ │
│*│ │ Behavior Specifications." Final Technical Report   │ │
│*│ │ SERC-2018-TR-116; Systems Engineering Research     │ │
│*│ │ Center: Hoboken, NJ, USA, 2018. Available online:  │ │
│*│ │ https://apps.dtic.mil/sti/citations/AD1063328      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, UAV; autonomous; behavior, unexpected    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1. This model contains an unexpected │ │
│*│ │ behavior in which the UAV status is acceptable but │ │
│*│ │ the operator aborts the ingress (trace 2).         │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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



