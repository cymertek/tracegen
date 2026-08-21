/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Autonomous Car                            │ │
│*│ │  Created by Gregory Kaminski in November, 2015.    │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ │  Edited by Kristin Giammarco in September, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the use of COORDINATE statements to  │ │
│*│ │ improve the quality of trace analysis.             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a model of an autonomous car that was      │ │
│*│ │ developed as part of a student project to support  │ │
│*│ │ a failure mode analysis of autonomous automobile   │ │
│*│ │ technology. It applies COORDINATE statements to    │ │
│*│ │ add dependencies between the events within the     │ │
│*│ │ roots "Car" and "User". Without the COORDINATE     │ │
│*│ │ statements, the event traces produce invalid or    │ │
│*│ │ erroneous combinations of events from different    │ │
│*│ │ roots, such as the car behaving as if it had       │ │
│*│ │ arrived at its destination when in fact it had     │ │
│*│ │ not.                                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Kaminski, Gregory J. "Failure Mode Analysis of 	 │ │
│*│ │ Autonomous Automobile Technology Using Monterey    │ │
│*│ │ Phoenix." Master's Project, Stevens Institute of   │ │
│*│ │ Technology. December 2015.                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, autonomous car; autonomous;              │ │
│*│ │ analysis, failure mode; coordination, event        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1. Inspect the traces, then remove   │ │
│*│ │ one or more of the constraints. Run again, and     │ │
│*│ │ inspect the traces for potential invalid or        │ │
│*│ │ erroneous behaviors.                               │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec. (with all    │ │
│*│ │ constraints)                                       │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Autonomous_Car

/*Actors*/

ROOT Car: 	Search_for_Destination
			
			( Prompt_for_New_Destination | 
                Find_Destination )
			
			Begin_Trip
			Drive
			Reach_Destination
			Confirm_Trip_Complete

			( End_Trip | 
                Start_New_Trip);

	Find_Destination: Confirm_Destination_Found;


ROOT User: 	Enter_Car
			Enter_Desired_Destination

			( Enter_New_Destination | 
                Confirm_Destination )

			( Confirm_Destination_Reached | 
                Destination_Not_Reached );


/*Interactions*/

COORDINATE 	$a: Enter_Desired_Destination 	FROM User,
			$b: Search_for_Destination 		FROM Car
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Prompt_for_New_Destination 	FROM Car,
			$b: Enter_New_Destination 		FROM User
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Confirm_Trip_Complete 			FROM Car,
			$b: ( Confirm_Destination_Reached | 
                	Destination_Not_Reached ) 	FROM User
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Confirm_Destination_Found 	FROM Car,
			$b: Confirm_Destination 		FROM User
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: ( Enter_New_Destination | 
    				Confirm_Destination ) 	FROM User,
			$b: Begin_Trip 					FROM Car
	DO ADD $a PRECEDES $b; OD;
