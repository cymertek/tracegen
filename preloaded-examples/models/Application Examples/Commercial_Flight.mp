/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Commercial Flight                         │ │
│*│ │  Created by Mikhail Auguston on the 27th of        │ │
│*│ │     November, 2013.                                │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show a system with many roots performing        │ │
│*│ │ multiple actions, using COORDINATE and SHARE ALL   │ │
│*│ │ statements to make a web of actions linked         │ │
│*│ │ together through phases.                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates the interlacing of root    │ │
│*│ │ events as Phases and as Actors, in order to model  │ │
│*│ │ a commercial flight.                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 15: Standard flight model." from          │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Auguston, Mikhail, Kristin Giammarco,              │ │
│*│ │    W. Clifton Baldwin, Ji’on Crump, and            │ │
│*│ │    Monica Farah-Stapleton. (2015). "Modeling and   │ │
│*│ │    verifying business processes with Monterey      │ │
│*│ │    Phoenix." Procedia Computer Science 44: 48-57.  │ │
│*│ │                                                    │ │
│*│ │ Giammarco, Kristin, Mikhail Auguston,              │ │
│*│ │    W. Clifton Baldwin, Ji’on Crump, and            │ │
│*│ │    Monica Farah-Stapleton. (2014). "Controlling    │ │
│*│ │    Design Complexity with the Monterey Phoenix     │ │
│*│ │    Approach." Procedia Computer Science 36:        │ │
│*│ │    204-209.                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, commercial flight; event sharing;        │ │
│*│ │ coordination, event                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in approx. 2.7 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Flight

/*-----------------------------------------------------
 	Main Flight Phases
-----------------------------------------------------*/

ROOT Preflight: BoardAircraft 		
				FlightCheck 
				DepartureClearance  	
				Pushback 
				IssueGroundInstruction 	
				Taxi ;

ROOT Takeoff: 	(* Hold_in_queue *)		
				Clear_for_takeoff 	
				Liftoff 
				Handoff_to_TRACon ;

ROOT Departure: ChangeFrequency 
				IssueClearances 
				Handoff_to_ARTCC ;

ROOT EnRoute: 	IssueInstruction
				( OceanicExtension | Follow_route )
				ChangeFrequency2 
				Handoff_to_TRACon2 ;

ROOT Descent: 	Clear_descent
				Maneuver_toward_Airport ;

ROOT Approach: 	(* Hold *) 	
				Clear_approach
				Enter_approach_line
				Handoff_to_tower ;

ROOT Landing: 	Clear_landing
				Land
				Taxi_instruction
				Taxi_to_gate
				Disembark ;

/*-----------------------------------------------------
	Actors
-----------------------------------------------------*/

ROOT Passenger: BoardAircraft 
				InsideCabin 
				Disembark ;

ROOT Pilot: 	FlightCheck 
				Pushback 
				Taxi 
				(* Hold_in_queue *)
				Clear_for_takeoff
				Liftoff 	
				ChangeFrequency
				( OceanicExtension | Follow_route )
				ChangeFrequency2
				Maneuver_toward_Airport
				(* Hold *)	
				Enter_approach_line
				Land
				Taxi_to_gate ;

ROOT Controller: 	DepartureClearance 
					IssueGroundInstruction 
					Clear_for_takeoff 	
					Handoff_to_TRACon
					IssueClearances 
					Handoff_to_ARTCC 
					IssueInstruction 
					Handoff_to_TRACon2
					Clear_descent
					Clear_approach
					Handoff_to_tower
					Clear_landing
					Taxi_instruction ;

/*---------------------------------------------------
   Interactions between phases 
/*---------------------------------------------------*/

COORDINATE 	$a: Taxi FROM Preflight,
			$b: Clear_for_takeoff FROM Takeoff
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Handoff_to_TRACon FROM Takeoff,
			$b: IssueClearances FROM Departure
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a:Maneuver_toward_Airport FROM Descent,
			$b:Clear_approach FROM Approach
	DO ADD $a PRECEDES $b; OD;

/*-----------------------------------------------------
	Overlapping between actors and process phases
-----------------------------------------------------*/

Passenger, Preflight  	SHARE ALL 	BoardAircraft;

Passenger, Landing 		SHARE ALL 	Disembark;

Pilot, Preflight 		SHARE ALL 	FlightCheck, 
									Pushback, 
									Taxi;

Pilot, Takeoff 	  	SHARE ALL 	Hold_in_queue,
								Liftoff;

Pilot, Departure 	SHARE ALL 	ChangeFrequency;

Pilot, EnRoute 	  	SHARE ALL 	OceanicExtension,
								Follow_route, 
								ChangeFrequency2;

Pilot, Descent 	  	SHARE ALL 	Maneuver_toward_Airport;

Pilot, Approach 	SHARE ALL 	Hold, 
								Enter_approach_line;

Pilot, Landing 		SHARE ALL 	Land,
								Taxi_to_gate;

Controller, Preflight 	SHARE ALL 	DepartureClearance, 
									IssueGroundInstruction;

Controller, Takeoff   	SHARE ALL 	Clear_for_takeoff, 		
									Handoff_to_TRACon;

Controller, Departure 	SHARE ALL 	IssueClearances,
									Handoff_to_ARTCC;

Controller, EnRoute   	SHARE ALL 	IssueInstruction, 
									Handoff_to_TRACon2;

Controller, Descent   	SHARE ALL 	Clear_descent;


Controller, Approach  	SHARE ALL 	Clear_approach,
									Handoff_to_tower;

Controller, Landing 	SHARE ALL 	Clear_landing,
									Taxi_instruction;
