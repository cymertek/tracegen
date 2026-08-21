/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 24. ATM Withdrawal with Global Graph       │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the construction of a global graph  │ │
│*│ │ from all traces in the schema.                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model builds upon the ATM Withdrawal behavior │ │
│*│ │ from Example 4 in the MP manual. It shows how to   │ │
│*│ │ extract a global graph in the form of a physical   │ │
│*│ │ architecture view (commonly called a component     │ │
│*│ │ diagram) from the set of valid event traces. The   │ │
│*│ │ MP code for constructing a UML-like Component      │ │
│*│ │ Diagram is reusable and can be copied/pasted into  │ │
│*│ │ any MP model.                                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 42: Graph in the Global view" from        │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Example 4: Withdraw money from ATM model" from    │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, ATM withdrawal; report, global;          │ │
│*│ │ graph, component diagram; UML diagram, component;  │ │
│*│ │ SysML diagram, component                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 13 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 40 traces in approx. 12 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA ATM_Withdrawal_with_Component_Diagram

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

/*================================================================
 Processing event trace to find dependencies between components.
 Produces a UML-like Component Diagram. This code is reusable, 
 and can be copied/pasted into any other MP model.
  ================================================================*/
GRAPH Component_Diagram { TITLE ("Diagram of Component Interactions");};

	COORDINATE 	$E1: ($$ROOT | $$COMPOSITE) DO 
		COORDINATE	$E2: ($$ROOT | $$COMPOSITE) DO
			WITHIN Component_Diagram{
    /* For each valid event trace find all root and composite 
        event instances within the event trace and add them to the graph. */ 
		 		Node$a: LAST ($E1);
				Node$b: LAST ($E2);
	/* LAST option in the node constructors ensures
    	there will be only a single instance of a node 
		in the graph for each root and composite event 
        found in the event trace */

	/* If event E1 is IN another event E2, add an arrow “E2 calls E1” */
				IF $E1 IN $E2 THEN
  					ADD Node$b ARROW("calls") Node$a; 
				FI;
	
   /* We look for interactions between components and data structures.

	Interactions between components, usually are represented by coordination of 
	events in the interacting components (presence of PRECEDES between events 
    in different threads).
    
 	Interactions between components and data structures are modeled by shared events, 
    since data structures are usually modeled as a set of operations performed on them. */ 
		
				IF  $E1 !=  $E2 	                        AND
                	NOT ($E1 IN $E2 OR $E2 IN $E1) 			AND
               		(	( EXISTS 	$E3: $$EVENT ($E3 IN $E1 AND $E3 IN $E2) ) OR
                        
  			   			( EXISTS 	$E3: $$EVENT FROM $E1, 
                			  		$E4: $$EVENT FROM $E2 ($E3 PRECEDES $E4) ) ) 	THEN
  			   			ADD Node$a LINE("interacts with") Node$b;
                FI;
            }; /* end WITHIN Diagram */
		OD; 
	OD; /* end of $E1 and $E2 loops */

GLOBAL
/* When trace derivation is completed, data from the traces has been accumulated in
	 the graph and is ready to be shown */
SHOW Component_Diagram;

