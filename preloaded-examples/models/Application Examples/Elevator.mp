/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Elevator                                  │ │
│*│ │  Created by Kristin Giammarco in 2011.             │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how under-constraining a model can  │ │
│*│ │ be beneficial, because it can lead to emergent     │ │
│*│ │ behavior showing up in the traces.                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This demonstrates the modeling of situations and   │ │
│*│ │ consequential events in MP. The pattern is:        │ │
│*│ │                                                    │ │
│*│ │ (         SituationA do_one_thing     |            │ │
│*│ │ SituationB do_another_thing )                      │ │
│*│ │                                                    │ │
│*│ │ in the case of this model,                         │ │
│*│ │                                                    │ │
│*│ │ (         Elevator_works_fine Get_Off |            │ │
│*│ │ Emergency_Situation Call_for_help )                │ │
│*│ │                                                    │ │
│*│ │ Ultimately, this is a simple model of an emergency │ │
│*│ │ scenario involving an elevator with very few       │ │
│*│ │ constraints. This allows for more variance, which  │ │
│*│ │ leads to emergent behavior. Users should use this  │ │
│*│ │ as an example of how under-constraining your model │ │
│*│ │ can be beneficial for gaining insights about       │ │
│*│ │ behaviors that may be possible but have not been   │ │
│*│ │ thoroughly considered. Constraints should be       │ │
│*│ │ limited to necessity in order to remove traces     │ │
│*│ │ that no longer need to be considered. When in      │ │
│*│ │ doubt, comment it out. Bring it back later if      │ │
│*│ │ needed.                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Buede, Dennis M. "The Engineering Design of        │ │
│*│ │ Systems: Models and Methods." (2009).              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, elevator; event sharing;                 │ │
│*│ │ coordination, event; behavior, emergent            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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

                 
