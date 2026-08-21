/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Surgery                                   │ │
│*│ │  Created by John Quartuccio in 2017.               │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the modeling of a decision pattern   │ │
│*│ │ involving several actors, including the            │ │
│*│ │ environment.                                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model shows an example of decisions made by a │ │
│*│ │ leader (Physician), a subordinate(s) (Nurse(s)),   │ │
│*│ │ and the Environment as applied in a surgery        │ │
│*│ │ setting. In general, it demonstrates               │ │
│*│ │ decisionmaking in a system with several actors     │ │
│*│ │ capable of making choices that could affect the    │ │
│*│ │ situation. Users may reference this model to learn │ │
│*│ │ about using ENSURE statements to constrain a model │ │
│*│ │ and how to make a decision structure.              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Quartuccio, John, Kristin Giammarco, and           │ │
│*│ │ Mikhail Auguston. "Identifying decision patterns   │ │
│*│ │ using Monterey Phoenix." 2017 12th System of       │ │
│*│ │ Systems Engineering Conference (SoSE), June 2017.  │ │
│*│ │ https://doi.org/10.1109/sysose.2017.7994952        │ │
│*│ │ https://ieeexplore.ieee.org/document/7994952       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, surgery; behavior, environment;          │ │
│*│ │ behavior, decision pattern; failure modes;         │ │
│*│ │ isomorphism                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 12 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
