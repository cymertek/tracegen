/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Agile Production Platform with Customer   │ │
│*│ │    Interactions                                    │ │
│*│ │  Created collaboratively in Teams by               │ │
│*│ │     Kristin Giammarco, Michael Collins, and        │ │
│*│ │     Elena Griffor on the 20th of August, 2020.     │ │
│*│ │  Modified collaboratively in Teams by              │ │
│*│ │     Kristin Giammarco and Joshua Beaver on the     │ │
│*│ │     17th of September, 2020.                       │ │
│*│ │  Edited by Pamela Dyer in September, 2021.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate a model that facilitates agreement   │ │
│*│ │ on a baseline typical use case for a Customer      │ │
│*│ │ placing an order using the "Agile Production       │ │
│*│ │ Platform" (APP). Here the order is for face        │ │
│*│ │ shields in response to the COVID-19 pandemic.      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using MP to find both      │ │
│*│ │ desired and undesired scenarios of Personal        │ │
│*│ │ Protective Equipment (PPE) supply chains within    │ │
│*│ │ the APP. The APP represents the linkage platform   │ │
│*│ │ being designed to enable agile production /        │ │
│*│ │ building of alternative supply chains.             │ │
│*│ │                                                    │ │
│*│ │ Specifically in this model, the focus is on the    │ │
│*│ │ delivered quality of 5,000 medical face shields (a │ │
│*│ │ Customer placed the order using the APP). Running  │ │
│*│ │ this model at Scope 1 generates four event traces, │ │
│*│ │ described as follows:                              │ │
│*│ │    Trace 1: The order is delivered to the Customer │ │
│*│ │       and meets their expectations (Favorable      │ │
│*│ │       Outcome).                                    │ │
│*│ │    Trace 2: The order is delivered to the Customer │ │
│*│ │       and does not meet their expectations         │ │
│*│ │       (Unfavorable Outcome, as well as Unexpected  │ │
│*│ │       Emergent Behavior that manifested as a       │ │
│*│ │       counterfeit part which made its way into the │ │
│*│ │       APP supply chain).                           │ │
│*│ │    Trace 3: The order is not delivered to the      │ │
│*│ │       Customer (Unfavorable Outcome, as well as    │ │
│*│ │       Expected Emergent Behavior).                 │ │
│*│ │    Trace 4: The Customer is notified by the APP    │ │
│*│ │       that the order cannot be completed at this   │ │
│*│ │       time because no alternative supply chain can │ │
│*│ │       be found (Unfavorable Outcome).              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Appendix A in Beaver, Joshua. "Analyzing Emergent  │ │
│*│ │ Behavior of Supply Chains for Personal Protective  │ │
│*│ │ Equipment in Response to COVID-19." NPS Master's   │ │
│*│ │ Thesis, Monterey, CA: September 2021.              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, supply chain; coordination, event;       │ │
│*│ │ SAY statement; trace annotation; event sharing;    │ │
│*│ │ table; behavior, unexpected; behavior, emergent;   │ │
│*│ │ behavior, agile production platform                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1. Reviewers of this model are       │ │
│*│ │ invited to provide feedback for better-named       │ │
│*│ │ events, other events that may occur normally or as │ │
│*│ │ a disruption to the sequence, missing or incorrect │ │
│*│ │ interactions, and the partitioning of the high     │ │
│*│ │ level APP functions for architectural cohesion.    │ │
│*│ │ Lower-level (implementation) activities have been  │ │
│*│ │ deliberately omitted for now in order to reach     │ │
│*│ │ consensus on intended use at the highest level of  │ │
│*│ │ abstraction.                                       │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Agile_Production_Platform_Customer_Interactions

ROOT Customer: 		Log_into_APP
					Input_a_need_for_5000_medical_face_shields
                        
					(	Receive_potential_solutions
						Filter_sort_inspect_presented_solutions
						Select_solution
						Place_order
					
                      (	Receive_order
                        ( Order_meets_expectations 	|
                          
                            Order_does_not_meet_expectations )	|
                        
                        Does_not_receive_order )	|
                        
                        	Unable_to_place_order );


ROOT APP: 	{ 	Handle_User_Interactions, 
    			Manage_Supply_Chain_Options};

Handle_User_Interactions: 	Authenticate_Customer_credentials
    						Prompt_Customer_for_need
							Send_customer_order
							(	Alternative_supply_chain_found
    							Display_potential_solutions_with_attributes
    							Place_orders_on_behalf_of_Customer	|
                                
                                	Alternative_supply_chain_NOT_found
                                	Notify_customer_order_cannot_be_completed );

Manage_Supply_Chain_Options:	{ 	Identify_individual_components_of_needed_item
    								Prepare_component_search_parameters
    								Find_component_matches
    								
    								Construct_list_of_valid_supply_chains
    								( Complete_supply_chain_available Provide_list_to_user	|
                                        
                                        Complete_supply_chain_unavailable ),
    
    								Data_for_supply_chain
    							};


COORDINATE $a: Log_into_APP							FROM Customer,
           $b: Authenticate_Customer_credentials	FROM APP
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Prompt_Customer_for_need						FROM APP,
           $b: Input_a_need_for_5000_medical_face_shields	FROM Customer
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Input_a_need_for_5000_medical_face_shields		FROM Customer,
           $b: Send_customer_order								FROM APP
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Send_customer_order								FROM APP,
           $b: Identify_individual_components_of_needed_item	FROM APP
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Provide_list_to_user							FROM APP,
           $b: Display_potential_solutions_with_attributes	FROM APP
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Display_potential_solutions_with_attributes		FROM APP,
           $b: Receive_potential_solutions						FROM Customer
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Place_order							FROM Customer,
           $b: Place_orders_on_behalf_of_Customer	FROM APP
    DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: Notify_customer_order_cannot_be_completed	FROM APP,
           $b: Unable_to_place_order						FROM Customer
    DO ADD $a PRECEDES $b ; OD;


ROOT Data_Services_Resources: 	Data_for_supply_chain;

/*  Abstracted out for now.  Will elaborate in a separate MP model.
								{ 	[ Suppliers ],
									[ Shippers ],
									[ Manufacturers ],
									[ Distributers ],
    								[ Design_Engineering ],
									[ Shipping_Distribution ],
									[ Customer_Services ],
									[ Market_Services ],
    								[ Purchase_Order_Contract_Payment ] 	
								};

*/

Data_Services_Resources, APP SHARE ALL Data_for_supply_chain;



/*------------------------ TABLES, CHARTS & DIAGRAMS --------------------------*/

COORDINATE $a: $$EVENT
DO
/* Customer durations, placeholder values only */
	IF $a IS Log_into_APP 									THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Input_a_need_for_5000_medical_face_shields 	THEN SET $a.duration AT LEAST 5; FI;
  	IF $a IS Receive_potential_solutions 					THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Filter_sort_inspect_presented_solutions 		THEN SET $a.duration AT LEAST 20; FI;
  	IF $a IS Select_solution 								THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Place_order 									THEN SET $a.duration AT LEAST 3; FI;
/* APP durations, placeholder values only */
	IF $a IS Authenticate_Customer_credentials 				THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Prompt_Customer_for_need 						THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Send_customer_order 							THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Identify_individual_components_of_needed_item 	THEN SET $a.duration AT LEAST 5; FI;
  	IF $a IS Prepare_component_search_parameters 			THEN SET $a.duration AT LEAST 5; FI;
	IF $a IS Find_component_matches 						THEN SET $a.duration AT LEAST 60; FI;
  	IF $a IS Construct_list_of_valid_supply_chains 			THEN SET $a.duration AT LEAST 10; FI;
  	IF $a IS Provide_list_to_user 							THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Display_potential_solutions_with_attributes 	THEN SET $a.duration AT LEAST 1; FI;
  	IF $a IS Place_orders_on_behalf_of_Customer 			THEN SET $a.duration AT LEAST 1; FI;
OD;


/* Durations Table */

TABLE Durations_Table 	{ 
							TABS 	string Event_name, 
									number Start_time, 
									number Duration_time;
						};


/* Gantt Chart */

BAR CHART 	Gantt_Chart { TITLE("Gantt Chart");
	FROM 	Durations_Table;
	X_AXIS Event_name;
	ROTATE; /* to place the X_AXIS vertical */
};

COORDINATE $e: $$EVENT
	DO 	/* add this event to the Table */ 
		Durations_Table 		<|
			Event_name: 	SAY($e),
			Start_time: 	$e.start.smallest,
			Duration_time:  $e.duration.largest;
	OD;



/* Display on Output */

/*SHOW Durations_Table;
SHOW Gantt_Chart;
SHOW ACTIVITY DIAGRAM APP;*/

/*----------------------------------- QUESTIONS ------------------------------------*/

COORDINATE $x: Customer 
			DO  ADD SAY("What additional interactions for the Customer may be needed " 
                		"while the Customer is waiting for the order?")
  					PRECEDES $x;
			OD;


/*----------------------------------- COMMENTS -------------------------------------*/

SAY("Partitioned the APP into user-facing " "and back end-facing functionality.");

COORDINATE $x: Data_for_supply_chain 
			DO  ADD SAY("Represents asynchronous and continuous data " 
                		"for support to the alternative supply chain construction.")
  					PRECEDES $x;
			OD;

IF #Order_meets_expectations > 0 THEN
SAY("Favorable Outcome");
FI;

IF #Order_does_not_meet_expectations > 0 THEN
SAY("Unfavorable Outcome");
FI;

IF #Does_not_receive_order > 0 THEN
SAY("Unfavorable Outcome");
FI;

IF #Unable_to_place_order > 0 THEN
SAY("Unfavorable Outcome");
FI;
