/* Example 40. MP Web browsers formal security model.
   
based on the papers by: 

Daniel Jackson
Alloy: A Language and Tool for Exploring Software Designs
Communications of the ACM, September 2019, Vol. 62 No. 9, Pages 66-76

and 

Akhawe, D., Barth, A., Lam, P.E., Mitchell, J. and Song, D. 
Towards a formal foundation of Web security. 
In Proceedings of the 23rd IEEE Computer Security Foundations Symp. 
Edinburgh, 2010, 290–304.

In particular, we've found very inspiring the sentences from the 
Akhave et al.:

"We believe that examining the set of possible events
accurately captures the way that web security mechanisms
are designed" (page 292)

and 

"The browser, server, and network behavior
form the “backbone” of the model" (page 292) 

This has motivated to design the MP behavior model of the web activities 
in order to model the vulnerabilities explained in the papers above.

	run for scope 1: 3 traces, no counterexamples for Property1, in less than 0.001 sec.
    run for scope 2: 7 traces, 1 counterexample for Property1, in 0.13 sec.
    run for scope 3: 52 traces, 16 counterexamples for Property1, in 15 sec.
    
    This example borrowed from Daniel Jackson's paper demonstrates 
    how MP can check whether Client's web query may 
	be indirectly affected by Bad Server's Redirect intervention.
    
==============================================================================*/
SCHEMA Web_browser

/* Response may embed some Request events,
	Only Responses from Bad_Server contain Redirect */
Response: {* Request *} [ Redirect ] Send_Response
BUILD{ 
    COORDINATE $r: Request
    	DO 
    		ADD THIS causes $r;
    	OD;
};

/* Client starts interactions */
ROOT Client: Request (+ (Request | Process_Response | Response ) +)
BUILD{ 
    ENSURE #Redirect == 0;

    ENSURE #Request == #Process_Response; };


ROOT Good_Server: (*<0 .. $$scope + 1> (Request | Process_Response | Response ) *) 
BUILD{ 
    ENSURE #Redirect == 0;

    ENSURE #Request == #Process_Response; }; 


ROOT Bad_Server: (*<0 .. $$scope + 1>  (Request | Process_Response | Response ) *) 
BUILD{ 
    ENSURE #Response == #Redirect;
    
    ENSURE #Request == #Process_Response; }; 


COORDINATE 	$a: Request, 
			$b: Response,
			$c: Process_Response
	DO 	
		/* No Server should respond to its own Request */
		ENSURE FOREACH $s: $$ROOT NOT ($a FROM $s AND $b FROM $s);  
 
		/* allow only pairs Request/Process_Request from the same Server */
		ENSURE EXISTS $s: $$ROOT ($a FROM $s AND $c FROM $s);

		ADD $a PRECEDES $b; 
		ADD $a causes $b;

		/* to make the correspondence between Request/Process_Response more visible */
		ADD $b is_response_to $a; 

		COORDINATE $d: Send_Response FROM $b 
			DO
				ADD $d PRECEDES $c;
				ADD $d causes $c;
			OD;
	OD;

/* Client never does directly interact with Bad_Server */
ENSURE NOT EXISTS $r1: Request FROM Client, $r2: Response FROM Bad_Server ($r1 causes $r2);

/*=================== Property1 =========================
	 Check whether Client's Process_Response may 
	be indirectly affected by Bad_Server's Redirect intervention 
=========================================================*/
IF EXISTS $r1: Process_Response FROM Client, $r2: Redirect ($r2 BEFORE $r1) 
THEN    SAY("Response to Client may be affected by Bad Server");  
        MARK; 
FI;
