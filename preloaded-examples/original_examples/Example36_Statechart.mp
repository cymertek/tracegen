/* Example 36.

	Extracting Statechart view from MP model.
    
    run for scope 1 and up
==========================================================*/
SCHEMA ATM_withdrawal_with_Statechart_view

ROOT Customer: (* 	insert_card  
		    		(	identification_succeeds 
			 			request_withdrawal 
			 			(get_money | not_sufficient_funds) 	|
                        
			 			identification_fails 	    		) 
    				retrieve_card
				*);
				
ROOT ATM_system: (* Idle
    				read_card  	
		    		validate_id 
		    		( 	id_successful 
		       			check_balance 
		       			( 	sufficient_balance 	
			    			dispense_money   	 |    
			    			unsufficient_balance )  | 
                        
		        		id_failed  					)   	
		 		*)
				Idle;
	
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
 				sufficient_balance 		| unsufficient_balance),

	$user: /* these are User’s inputs that trigger ATM state transitions */
     		(insert_card | request_withdrawal | retrieve_card),

	<CUT_FRONT> $state2: /* these are ATM system’s states */ 
			( 	Idle | id_successful | id_failed | 
  				sufficient_balance | unsufficient_balance) 
	DO
		WITHIN Diagram{
 			ADD LAST ($state1) ARROW($user) LAST ($state2); };
	OD;

GLOBAL

SHOW Diagram;
