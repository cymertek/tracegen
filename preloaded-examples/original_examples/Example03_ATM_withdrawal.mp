/* Example3_ATM_withdrawal.mp
	Integrated system and environment behaviors
	
MP separates models of component behaviors and component interactions 
to permit elaboration on behaviors of multiple interacting actors.

"Withdraw money from ATM" is a popular example in software architecture literature.
This example demonstrates how behavior of both the system and its environment can be
integrated into a single MP model.

Separate behavior models account for alternative behaviors of not only the ATM System
under design, but also those of external components Customer and Database.
A separate specification of interactions captures the sharing and precedence dependencies
among events in different components.

The event traces produced from a model partitioned using this separation of concerns 
include all combinations of event selections allowed by the model.

Run for scopes 1 and up. 

The "Sequence" or "Swim Lanes" layouts are the most appropriate for browsing traces here. 
The "Sequence" mode yields views very similar to the UML or SysML Sequence Diagrams. 

By selecting a representative enough trace (containing all events and interactions of interest,
like traces 2 or 3 for scope 1), and then collapsing root event, it becomes possible 
to view a traditional "box-and-arrow" architecture diagram, i.e. to visualize an architecture view.

*/

SCHEMA ATM_withdrawal

ROOT Customer: 	(*  insert_card  
		    		( identification_succeeds 
					  request_withdrawal 
					  (get_money | not_sufficient_funds)  |
                        
					  identification_fails 	    		  )      
				*);
				
ROOT ATM_system: (* read_card  	
		    		validate_id 
		    		( id_successful 
		      		  check_balance 
		      		  ( sufficient_balance 	
			  			dispense_money   	 |
                          
			  			unsufficient_balance )  	| 
                        
		      		id_failed  					    )   	
		 		*);
	
/* behavior of the Data_Base follows interaction pattern with it in ATM_system,
    this makes it easier to coordinate these behaviors with SHARE ALL */
ROOT Data_Base:  	(*  validate_id  [ check_balance ] *);

/* interactions */
Data_Base,  ATM_system SHARE ALL validate_id, check_balance;

COORDINATE 	$x: insert_card	FROM Customer,  
			$y: read_card  	FROM ATM_system 
		DO 	ADD $x PRECEDES $y;  OD;
		
COORDINATE 	$x: request_withdrawal FROM Customer,  
			$y: check_balance      FROM ATM_system
		DO  ADD $x PRECEDES $y; OD;
		
COORDINATE 	$x: identification_succeeds  FROM Customer, 
			$y: id_successful   	     FROM ATM_system
	DO  	ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: get_money        FROM Customer,  
			$y: dispense_money   FROM ATM_system
	DO  	ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: not_sufficient_funds  	FROM Customer, 
			$y: unsufficient_balance  	FROM ATM_system
	DO  	ADD $y PRECEDES $x; OD;
	
COORDINATE 	$x: identification_fails   	FROM Customer, 
			$y: id_failed				FROM ATM_system
	DO  	ADD $y PRECEDES $x; OD;

	