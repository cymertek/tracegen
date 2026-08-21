/* A model of an autonomous car that was used to support a failure mode
analysis of autonomous automobile technology (student project). 
Created by G. Kaminski, November 2015
*/

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