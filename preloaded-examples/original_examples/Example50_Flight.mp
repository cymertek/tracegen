/* Model of a commercial flight, November 27, 2013

This model demonstrates the interlacing of root events as Phases 
and as Actors.  The commented out code at the bottom represents
a simulation of COORDINATE statements with SHARE ALL statements before
COORDINATE statements were implemented in the early MP tools.

*/

/*-----------------------------------------------------
 	Phases
-----------------------------------------------------*/

SCHEMA Flight



ROOT Preflight: BoardAircraft 		
				FlightCheck 
				DepartureClearance  	
				Pushback 
				IssueGroundInstruction 	
				Taxi ;

ROOT Takeoff: 	Clear_for_takeoff 	
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

ROOT Approach: 	[ Hold ] 	
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
				Liftoff 	
				ChangeFrequency
				( OceanicExtension | Follow_route )
				ChangeFrequency2
				Maneuver_toward_Airport
				[ Hold ] 		
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

/*-----------------------------------------------------
	Overlapping between actors and process phases
-----------------------------------------------------*/

Passenger, Preflight  	SHARE ALL 	BoardAircraft;

Passenger, Landing 		SHARE ALL 	Disembark;

Pilot, Preflight 		SHARE ALL 	FlightCheck, 
									Pushback, 
									Taxi;

Pilot, Takeoff 	  	SHARE ALL 	Liftoff;

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

/*---------------------------------------------------------
	Coordination between phases 
---------------------------------------------------------*/

COORDINATE	$a: BoardAircraft 	FROM Passenger, 
			$b: FlightCheck FROM Pilot,
			$c: DepartureClearance FROM Controller,
			$d: Pushback FROM Pilot,
			$e: IssueGroundInstruction FROM Controller,
			$f: ( Taxi | Hold ) FROM Pilot,
			$g: Clear_for_takeoff FROM Controller,
			$h: Liftoff FROM Pilot,
			$i: Handoff_to_TRACon FROM Controller,
			$j: ChangeFrequency FROM Pilot,
			$k: IssueClearances FROM Controller

	DO 	ADD $a PRECEDES $b,
 		    $b PRECEDES $c,
			$c PRECEDES $d,
			$d PRECEDES $e,
			$e PRECEDES $f,
			$f PRECEDES $g,
			$g PRECEDES $h,
			$h PRECEDES $i,
			$i PRECEDES $j,
			$j PRECEDES $k; OD;


COORDINATE	$a: IssueInstruction 	FROM Controller, 
			$b: ( OceanicExtension | Follow_route ) FROM Pilot,
			$c: ChangeFrequency2 FROM Pilot,
			$d: Handoff_to_TRACon2 FROM Controller,
			$e: Clear_descent FROM Controller,
			$f: ( Maneuver_toward_Airport | Hold ) FROM Pilot,
			$g: Clear_approach FROM Controller,
			$h: Enter_approach_line FROM Pilot,
			$i: Handoff_to_tower FROM Controller,
			$j: Clear_landing FROM Controller,
			$k: Land FROM Pilot,
			$l: Taxi_instruction FROM Controller,
			$m: Taxi_to_gate FROM Pilot,
			$n: Disembark FROM Passenger

	DO 	ADD $a PRECEDES $b,
 		    $b PRECEDES $c,
			$c PRECEDES $d,
			$d PRECEDES $e,
			$e PRECEDES $f,
			$f PRECEDES $g,
			$g PRECEDES $h,
			$h PRECEDES $i,
			$i PRECEDES $j,
			$j PRECEDES $k,
			$k PRECEDES $l,
			$l PRECEDES $m,
			$m PRECEDES $n; OD;

/*

ROOT Preflight_Takeoff: 	Taxi 
							Clear_for_takeoff ;

COORDINATE	$x: Taxi 	FROM Preflight, 
			$y: Clear_for_takeoff FROM Takeoff
	DO ADD $x PRECEDES $y; OD;

ROOT Takeoff_Departure: 	Handoff_to_TRACon
							ChangeFrequency ;

COORDINATE	$x: Handoff_to_TRACon 	FROM Takeoff, 
			$y: ChangeFrequency FROM Departure
	DO ADD $x PRECEDES $y; OD;

/* Departure and EnRoute are coordinated within Controller */

/* EnRoute and Descent are coordinated within Controller */

/*ROOT Descent_Approach: 		Maneuver_toward_Airport
							[ Hold ]
							Clear_approach ;

COORDINATE	$x: Handoff_to_TRACon 	FROM Descent, 
			$y: ChangeFrequency FROM Approach
	DO ADD $x PRECEDES $y; OD;

/* Approach and Landing are coordinated within Controller */
 
/*Preflight, Preflight_Takeoff 	SHARE ALL Taxi;

Preflight_Takeoff, Takeoff 		SHARE ALL Clear_for_takeoff;

Takeoff, Takeoff_Departure 		SHARE ALL Handoff_to_TRACon;

Takeoff_Departure, Departure 	SHARE ALL ChangeFrequency;

Descent, Descent_Approach 		SHARE ALL Maneuver_toward_Airport;

Descent_Approach, Approach  	SHARE ALL Hold, Clear_approach;

