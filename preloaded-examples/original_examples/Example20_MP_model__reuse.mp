SCHEMA 	Reuse_of_a_system

/* Example 20. 
	Authentication system's behavior for reuse with MAP operation.

	run for scope 3 or more to see attempts_exhausted event
	you may hide the Requestor node in the event trace graph,
	since the User will copy all Requestor's behavior

============== reused MP code starts here ==================*/
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
	mapping actions of the Requestor from Authentication_Service
	on actions of the User.
	User will copy/reuse all activities of Requestor
------------------------------------------------------------------*/
/* Requester's behavior is included into the behavior of User */
    MAP Requester ON User;

/*  synchronizing particular events from the authentication 
	system's behavior with events in the new system 		  */
COORDINATE 	$ready: access_granted 	FROM Requester,
			$go: 	login_succeeds	FROM User	
	DO ADD $ready PRECEDES $go; OD;
