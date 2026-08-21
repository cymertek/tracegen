/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Web Browser Formal Security               │ │
│*│ │  Created by Mikhail Auguston in 2019.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate using MP to model server-client     │ │
│*│ │ communication involving a bad server and a good    │ │
│*│ │ server.                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This example borrowed from (Jackson 2019)          │ │
│*│ │ demonstrates how MP can check whether Client's web │ │
│*│ │ query may be indirectly affected by Bad Server's   │ │
│*│ │ Redirect intervention. This has motivated to       │ │
│*│ │ design the MP behavior model of the web activities │ │
│*│ │ in order to model the vulnerabilities explained in │ │
│*│ │ the papers below. In particular, we've found very  │ │
│*│ │ inspiring the sentences from (Akhawe et al. 2010): │ │
│*│ │                                                    │ │
│*│ │ "We believe that examining the set of possible     │ │
│*│ │ events accurately captures the way that web        │ │
│*│ │ security mechanisms are designed" (page 292)       │ │
│*│ │                                                    │ │
│*│ │ and                                                │ │
│*│ │                                                    │ │
│*│ │ "The browser, server, and network behavior form    │ │
│*│ │ the “backbone” of the model" (page 292).           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 19: Web browsers formal security model."  │ │
│*│ │    from Auguston, M. "Monterey Phoenix System and  │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Jackson, Daniel. "Alloy: A Language and Tool for   │ │
│*│ │    Exploring Software Designs." Communications of  │ │
│*│ │    the ACM 62, no. 9 (September 2019): 66–76.      │ │
│*│ │    https://doi.org/10.1145/3338843                 │ │
│*│ │    https://dl.acm.org/doi/10.1145/3338843          │ │
│*│ │                                                    │ │
│*│ │ Akhawe, Devdatta, Adam Barth, Peifung E. Lam,      │ │
│*│ │    John Mitchell, and Dawn Song. "Towards a Formal │ │
│*│ │    Foundation of Web Security." In Proceedings of  │ │
│*│ │    2010 23rd IEEE Computer Security Foundations    │ │
│*│ │    Symposium, July 2010, 290–304.                  │ │
│*│ │    https://doi.org/10.1109/csf.2010.27             │ │
│*│ │    https://ieeexplore.ieee.org/document/5552637    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ formal security; behavior, web browser;            │ │
│*│ │ BUILD block; coordination,                         │ │
│*│ │ one-to-many; coordination, nested composition      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces (no counterexamples for          │ │
│*│ │    Property1) in less than 1 sec.                  │ │
│*│ │ Scope 2: 7 traces (including 1 counterexample for  │ │
│*│ │    Property1) in less than 1 sec.                  │ │
│*│ │ Scope 3: 52 traces (including 16 counterexamples   │ │
│*│ │    for Property1) in approx. 20 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
