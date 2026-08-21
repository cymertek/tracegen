/*******************************************************************************

A Model for Simple Authentication

A demonstration that shows how to reject unwanted behaviors with ENSURE 
constraints.
  
  created by K.Giammarco on 05/16/2017
  modified by K.Giammarco on 08/07/2017 for capitalization of state events
  modified by K.Giammarco on 08/07/2017 for ENSURE constraints
  
********************************************************************************/

SCHEMA Authentication

/*-----------------------
  USER BEHAVIORS
-------------------------*/

ROOT User: 	Provide_credentials
			  (* CREDS_INVALID Reenter_credentials *)
			 [ CREDS_VALID Access_system ];

/*-----------------------
  SYSTEM BEHAVIORS
-------------------------*/

ROOT System:	Verify_credentials
				(+ ( CREDS_INVALID Deny_access |
                    	CREDS_VALID Grant_access ) +)
				[ Lock_account ]
                ;

/*-----------------------
  INTERACTION CONSTRAINTS
-------------------------*/

User, System SHARE ALL CREDS_VALID, CREDS_INVALID;

COORDINATE 	$a: Provide_credentials	FROM User,
			$b: Verify_credentials	FROM System
		DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Deny_access				FROM System,
			$b: Reenter_credentials 	FROM User
		DO ADD $a PRECEDES $b; OD; 

COORDINATE 	$a: Grant_access		FROM System,
			$b: Access_system		FROM User
		DO ADD $a PRECEDES $b; OD; 

ENSURE #CREDS_INVALID <= 3;

ENSURE #Deny_access >= 3 <-> #Lock_account == 1;

ENSURE #Grant_access >= 1 -> #Lock_account == 0;