/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 06. Model of Unreliable Channel            │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate assertion checking with MP.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a behavior model of communicating via an   │ │
│*│ │ unreliable channel. It is considered isomorphic    │ │
│*│ │ since the model structure can be reused - one can  │ │
│*│ │ change the event names while preserving the        │ │
│*│ │ structure and obtain a domain-specific model of    │ │
│*│ │ communication via an unreliable channel.           │ │
│*│ │                                                    │ │
│*│ │ MP models need to be tested and debugged like any  │ │
│*│ │ other programming artifacts. Trace generation for  │ │
│*│ │ a given scope yields exhaustive set of valid event │ │
│*│ │ traces. Browsing these traces may result in        │ │
│*│ │ finding examples of behavior that are unwanted.    │ │
│*│ │ Then we fix the issue in the MP code, and run the  │ │
│*│ │ trace generation again, until our expectations are │ │
│*│ │ satisfied.                                         │ │
│*│ │                                                    │ │
│*│ │ Browsing dozens or hundreds of event traces may be │ │
│*│ │ time consuming and error prone. The CHECK          │ │
│*│ │ construct makes it possible to use automated trace │ │
│*│ │ monitoring. If the property (Boolean expression in │ │
│*│ │ the CHECK) is not satisfied, the trace will be     │ │
│*│ │ marked and available for further inspection.       │ │
│*│ │                                                    │ │
│*│ │ This can significantly speed up the testing        │ │
│*│ │ process. Of course, if the property should always  │ │
│*│ │ hold, it makes sense to convert it into the ENSURE │ │
│*│ │ condition.                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 10: Communicating via unreliable channel  │ │
│*│ │ model" from Auguston, M. "Monterey Phoenix System  │ │
│*│ │ and Software Architecture and Workflow Modeling    │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, unreliable communications channel;       │ │
│*│ │ assertion checking; isomorphism                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 13 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 40 traces in less than 1.5 sec.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Unreliable_Channel

ROOT TaskA: (* 	A_sends_request_to_B
		    	( 	A_receives_data_from_B   	|  
					A_timeout_waiting_from_B  	)   
			*);	

ROOT Connector_A_to_B: 	
			(*  A_sends_request_to_B
				(  	B_receives_request_from_A
					B_sends_data_to_A
					( 	A_receives_data_from_B  	| 
						A_timeout_waiting_from_B 	) 	|
                    
			 		A_timeout_waiting_from_B 			)  
			*);				
/* A_timeout_waiting_from_B may happen because Connector_A_to_B 
	fails to pass a message from A to B, or from B to A */

TaskA, Connector_A_to_B SHARE ALL 	A_sends_request_to_B,
 									A_timeout_waiting_from_B,
									A_receives_data_from_B ;

ROOT TaskB: 	(* 	B_receives_request_from_A  	
					B_sends_data_to_A 
				*);

TaskB, Connector_A_to_B SHARE ALL 	B_receives_request_from_A,
  									B_sends_data_to_A ;

/* assertion checking will mark examples of traces where TaskA 
	does not receive the requested data and will attach a message 
    to the trace */
CHECK 	#A_sends_request_to_B 		FROM TaskA == 
		#A_receives_data_from_B 	FROM TaskA 
	ONFAIL SAY("loss of reception detected"); 
