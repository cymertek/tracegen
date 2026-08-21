/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 35. Model of Authentication System         │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate behavior reuse with the MAP         │ │
│*│ │ composition operation. Authentication system's     │ │
│*│ │ behavior for reuse with MAP operation.             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model of an authentication subsystem maps     │ │
│*│ │ reusable behaviors of a generic Requester onto     │ │
│*│ │ behaviors of a User. The MAP composition operation │ │
│*│ │ performs the event mapping between two instances   │ │
│*│ │ of behaviors.                                      │ │
│*│ │                                                    │ │
│*│ │ The root events Data_Base, Requester, and          │ │
│*│ │ Authentication_Service represent a typical         │ │
│*│ │ authentication system’s behavior. The Requester    │ │
│*│ │ requests access to services. The                   │ │
│*│ │ Authentication_Service requests that specific      │ │
│*│ │ credentials be provided. If the supplied           │ │
│*│ │ credentials are valid, the system authorizes the   │ │
│*│ │ Requester to access the services, otherwise it     │ │
│*│ │ notifies the Requester that the received           │ │
│*│ │ credentials are invalid and the Requester may      │ │
│*│ │ reattempt access up to two more times. At any time │ │
│*│ │ the Requester may decide to abandon the access     │ │
│*│ │ request.                                           │ │
│*│ │                                                    │ │
│*│ │ This architecture template is reused in the system │ │
│*│ │ under design represented in this model by the User │ │
│*│ │ root. The MAP operation merges the behavior of     │ │
│*│ │ Requester into the behavior of User by making a    │ │
│*│ │ copy of all relations, basic and user-defined, in  │ │
│*│ │ which Requester participates to the User event.    │ │
│*│ │ COORDINATE/ADD operation further synchronizes some │ │
│*│ │ events in User and in Requester.                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 36: Reuse of an authentication subsystem" │ │
│*│ │ from Auguston, M. "Monterey Phoenix System and     │ │
│*│ │ Software Architecture and Workflow Modeling        │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, authentication system; reuse;            │ │
│*│ │ MAP operation                                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up. Viewing of traces also    │ │
│*│ │ includes a "Swim Lanes" option. At Scope 3 and     │ │
│*│ │ above, the attempts_exhausted event can be seen.   │ │
│*│ │ You may hide the Requester node in the event trace │ │
│*│ │ graph, since the User will copy all Requester's    │ │
│*│ │ behavior.                                          │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 9 traces in less than 1 sec.              │ │
│*│ │ Scope 4: 9 traces in less than 1 sec.              │ │
│*│ │ Scope 5: 9 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA 	Authentication_System

ROOT Data_Base: (*  check_ID *);

ROOT Authentication_Service: 	
	request_ID
	(* creds_invalid 	request_ID *)

	( 	creds_invalid 	
		[ attempts_exhausted ]  
		cancel_access_request 	|

		creds_valid   
		access_granted 		   	 )

BUILD{ 	/*--- constraints for this root ---*/
	ENSURE #creds_invalid <= 3; /* no more than 3 attempts to get access */
	ENSURE #attempts_exhausted == 1 <-> #creds_invalid == 3;
	IF #attempts_exhausted > 0 THEN SAY("  attempts exhausted!");FI;  }   
;

request_ID: check_ID;

Authentication_Service, Data_Base SHARE ALL check_ID;

ROOT Requester: 	
	request_access
	provide_ID 
	(* creds_invalid 	request_access  provide_ID *)

	( creds_valid  	
	  ( access_granted | abandon_access_request) 		|

	  creds_invalid  	
	  ( attempts_exhausted | abandon_access_request ) 	)
; 

Requester, Authentication_Service SHARE ALL 
								creds_valid,  		 creds_invalid, 
								attempts_exhausted, access_granted;

COORDINATE 	$a: request_access 	FROM Requester,
			$b: request_ID 		FROM Authentication_Service, 
			$c: provide_ID 		FROM Requester
	DO	ADD $a PRECEDES $b;	
		ADD $b PRECEDES $c;
	OD;
/*================= end of reused MP code =======================*/


/*===============================================================*/
/* new system, which will reuse authentication system's behavior */
/*---------------------------------------------------------------*/
ROOT User: 	

	( login_succeeds 
	  ( work 	| 
	  	/* User may change their mind and cancel login */
		cancel 	)			|

	  login_fails  			)
;


/*================================================================*/
/* 	the following adjustments of the new model and the reused one 
	are needed to integrate their behaviors.

	reuse of authentication system's behavior: 
	mapping actions of the Requester from Authentication_Service
	on actions of the User.
	User will copy/reuse all activities of Requester
------------------------------------------------------------------*/
/* Requester's behavior is included into the behavior of User */
    MAP Requester ON User;

/*  synchronizing particular events from the authentication 
	system's behavior with events in the new system 		  */
COORDINATE 	$ready: access_granted 	FROM Requester,
			$go: 	login_succeeds	FROM User	
	DO ADD $ready PRECEDES $go; OD;
