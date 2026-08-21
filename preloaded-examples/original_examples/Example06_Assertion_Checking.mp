/* Example6 Assertion checking, Communicating via unreliable channel.

	MP models need to be tested and debugged like any other 
    programming artifacts. Trace generation for a given scope 
    yields exhaustive set of valid event traces. 
    Browsing these traces may result in finding examples of behavior 
    that are unwanted. Then we fix the issue in the MP code, 
    and run the trace generation again, until our expectations are 
    satisfied. 

    Browsing dozens or hundreds of event traces may be time 
    consuming and error prone. The CHECK construct makes it possible 
    to use automated trace monitoring. If the property 
    (Boolean expression in the CHECK) is not satisfied, the trace will 
    be marked and available for further inspection. 
    
    This can significantly speed up the testing process. Of course, 
    if the property should always hold, it makes sense to convert it 
    into the ENSURE condition.
*/

SCHEMA AtoB

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
