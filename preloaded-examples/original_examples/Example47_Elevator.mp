/*Elevator Model

K.Giammarco circa 2011

This model demonstrates the modeling of situations and consequential events
in MP.  The pattern is:

( 	SituationA do_one_thing 	| 
	SituationB do_another_thing )
    
in the case of this model,

( 	Elevator_works_fine Get_Off |
    Emergency_Situation Call_for_help )
    
*/

SCHEMA ELEVATOR

ROOT Passenger :  Request_Up_Service
                  ( Available 
                    	Enter_Elevator
                  		Request_floor
                  		( 	Elevator_works_fine Get_Off |
                     		Emergency_Situation Call_for_help )  | 
                    Non_Available Elevator_works_fine Wait );
   
ROOT Elevator : (Available | Non_Available);

ROOT Maintenance_Personnel : ( 	Emergency_Situation 
                             	Instant_Response
                             	Provide_Exit_Opportunity | 
  								Elevator_works_fine
                               	Do_Nothing );

COORDINATE $a: Call_for_help FROM Passenger,
           $b: Instant_Response FROM Maintenance_Personnel
           DO ADD $a PRECEDES $b; OD;

Passenger, Elevator SHARE ALL Available, Non_Available;
Passenger, Maintenance_Personnel SHARE ALL Emergency_Situation, Elevator_works_fine;

                 