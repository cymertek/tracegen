/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 32. Model of ATM Withdrawal with           │ │
│*│ │ Statechart                                         │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to extract a Statechart view    │ │
│*│ │ from an MP model.                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ A statechart model is a diagram where states       │ │
│*│ │ represent states of the system and transitions     │ │
│*│ │ between states are triggered by events. The        │ │
│*│ │ following slightly adjusted ATM example (Example 4 │ │
│*│ │ in the MP language manual) demonstrates it. The    │ │
│*│ │ statechart is for the ATM System, so the states    │ │
│*│ │ graphed are those of ATM_system. The transitions   │ │
│*│ │ are events from the Customer acting as triggers to │ │
│*│ │ move between system states.                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 45: Extracting statechart view" from      │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, ATM withdrawal; graph, state transition; │ │
│*│ │ report, global                                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 13 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 40 traces in approx. 20 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA ATM_Withdrawal_with_Statechart

ROOT Customer: (* 	insert_card  								/* transition */
		    		(	identification_succeeds 
			 			request_withdrawal 						/* transition */
			 			(get_money | not_sufficient_funds) 	|
                        
			 			identification_fails 	    		) 	
    				retrieve_card								/* transition */
				*);
				
ROOT ATM_system: (* Idle										/* state */
    				read_card  	
		    		validate_id 
		    		( 	id_successful 							/* state */
		       			check_balance 
		       			( 	sufficient_balance 					/* state */
			    			dispense_money   	 |    
			    			unsufficient_balance )  | 			/* state */
                        
		        		id_failed  					)   		/* state */
		 		*)
				Idle;											/* state */
	
ROOT Data_Base: (*  validate_id  [ check_balance ] *);

/* Interactions */
Data_Base, ATM_system SHARE ALL validate_id, check_balance;

COORDINATE 	$x: insert_card	FROM Customer,  
			$y: read_card  	FROM ATM_system 
DO 	ADD $x PRECEDES $y; OD;
		
COORDINATE 	$x: request_withdrawal FROM Customer,  
			$y: check_balance      FROM ATM_system
DO  ADD $x PRECEDES $y; OD;
		
COORDINATE 	$x: identification_succeeds  FROM Customer, 
			$y: id_successful   	    FROM ATM_system
DO  ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: get_money        FROM Customer,  
			$y: dispense_money   FROM ATM_system
DO  ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: not_sufficient_funds  FROM Customer, 
			$y: unsufficient_balance  FROM ATM_system
DO  ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: identification_fails   	FROM Customer, 
			$y: id_failed				FROM ATM_system
DO  ADD $y PRECEDES $x; OD;

GRAPH Diagram{ TITLE("ATM state transition diagram"); };

/*===================================== 
	Building a graph proceeds here 
=======================================*/
COORDINATE 
	<CUT_END> $state1:  /* these are ATM system’s states */
			(	Idle | id_successful 	| id_failed |
 				sufficient_balance 		| unsufficient_balance ),

	$user: /* these are Customer's inputs that trigger ATM state transitions */
     		(insert_card | request_withdrawal | retrieve_card),

	<CUT_FRONT> $state2: /* these are ATM system’s states */ 
			( 	Idle | id_successful | id_failed | 
  				sufficient_balance | unsufficient_balance ) 
	DO
		WITHIN Diagram{
 			ADD LAST ($state1) ARROW($user) LAST ($state2); };
	OD;

GLOBAL

SHOW Diagram;
