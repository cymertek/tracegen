/* Surgery example 
This model shows an example of decisions made by a leader (Physician),
a subordinate(s) (Nurse(s)), and the Environment as applied in a surgery
setting.
"Identifying decision patterns using Monterey Phoenix" by Quartuccio, John, 
Kristin Giammarco, and Mikhail Auguston. 
Available at https://ieeexplore.ieee.org/abstract/document/7994952

Created by: J. Quartuccio (2017)
Naval Postgraduate School
*/

/*Actors*/
SCHEMA Surgery

ROOT Physician:	Routine_procedure
				Perception
				Leadership_context
				Decision;

	Perception:	( Recognize_environment | 
        			Not_recognize_environment );

	Leadership_context:	( Receive_input | 
        					Not_receive_input );
	Decision:	( Correct_decision | 
        			Incorrect_decision );

ROOT Nurses:	{+ Nurse +};
	
	Nurse:	Routine_procedure
					Perception
					Communication;

	Communication:	( Communicate_observation | 
        				Not_communicate_observation );

ROOT Environment:	Routine_procedure
					Problem_state
					Outcome_state;

	Problem_state:	( Problem | 
        				No_problem );
	
	Outcome_state:	( Successful_outcome | 
        				Failed_outcome );

/*Interactions*/

COORDINATE
$a: Leadership_context FROM Physician
DO COORDINATE
$b: ( Communicate_observation
| Not_communicate_observation ) FROM Nurses
DO ADD $b PRECEDES $a; OD;
OD;

COORDINATE
$a: Decision FROM Physician,
$b: Outcome_state FROM Environment
DO ADD $a PRECEDES $b; OD;

Physician, Nurses, Environment SHARE ALL Routine_procedure;

ENSURE (#No_problem FROM Environment == 1 ->
#Successful_outcome
FROM Environment == 1);

ENSURE(#Not_communicate_observation FROM
Nurses - #Nurse == 0 ->
#Not_receive_input FROM Physician == 1);

ENSURE(#Recognize_environment FROM Physician
- #Not_receive_input == 0 ->
#Correct_decision == 1);

ENSURE (#Receive_input FROM Physician == 1 ->
#Correct_decision FROM Physician == 1);
ENSURE (#Not_receive_input FROM Physician == 1 ->
#Incorrect_decision FROM Physician == 1);

ENSURE (#Correct_decision FROM Physician == 1 ->
#Successful_outcome FROM Environment
==1);
ENSURE (#Incorrect_decision FROM Physician == 1 ->
#Failed_outcome FROM Environment ==1);