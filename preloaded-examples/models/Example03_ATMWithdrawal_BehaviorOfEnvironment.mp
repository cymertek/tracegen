/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 03. Model of ATM Withdrawal                │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate integrated system and environment    │ │
│*│ │ behaviors.                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ MP separates models of component behaviors and     │ │
│*│ │ component interactions to permit elaboration on    │ │
│*│ │ behaviors of multiple interacting actors.          │ │
│*│ │                                                    │ │
│*│ │ "Withdraw money from ATM" is a popular example in  │ │
│*│ │ software architecture literature. This example     │ │
│*│ │ demonstrates how behavior of both the system and   │ │
│*│ │ its environment can be integrated into a single MP │ │
│*│ │ model.                                             │ │
│*│ │                                                    │ │
│*│ │ Separate behavior models account for alternative   │ │
│*│ │ behaviors of not only the ATM System under design, │ │
│*│ │ but also those of external components Customer and │ │
│*│ │ Database. A separate specification of interactions │ │
│*│ │ captures the sharing and precedence dependencies   │ │
│*│ │ among events in different components.              │ │
│*│ │                                                    │ │
│*│ │ The event traces produced from a model partitioned │ │
│*│ │ using this separation of concerns include all      │ │
│*│ │ combinations of event selections allowed by the    │ │
│*│ │ model.                                             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 4: Withdraw money from ATM model" from    │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, ATM withdrawal; behavior, environment    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up. The "Swim Lanes" view     │ │
│*│ │ under Options in the graph pane yields views very  │ │
│*│ │ similar to the UML or SysML Sequence Diagrams.     │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 13 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 40 traces in approx. 12 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA ATM_Withdrawal

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

	
