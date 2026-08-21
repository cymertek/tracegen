/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Authentication                            │ │
│*│ │  Created by Kristin Giammarco on the 16th of May,  │ │
│*│ │     2017.                                          │ │
│*│ │  Modified by Kristin Giammarco on the 7th of       │ │
│*│ │     August, 2017 to add capitalization to state    │ │
│*│ │     events and ENSURE constraints.                 │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to reject unwanted behaviors    │ │
│*│ │ with ENSURE constraints.                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates how to correctly model a   │ │
│*│ │ simple user authentication system with ENSURE      │ │
│*│ │ statements. ENSURE statements in this model are    │ │
│*│ │ used to lock the account if 3 or more incorrect    │ │
│*│ │ passwords are input, and guarantee that the        │ │
│*│ │ account will not be locked if a correct password   │ │
│*│ │ is input within the maximum number of attempts.    │ │
│*│ │ These constraints provide a maximum number of      │ │
│*│ │ allowable attempts and prevent unwanted traces     │ │
│*│ │ (ex. correct password leading to lock account),    │ │
│*│ │ respectively. The model demonstrates how users can │ │
│*│ │ remove unwanted traces in their models using       │ │
│*│ │ ENSURE.                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Giammarco, Kristin. (2017). “Practical Modeling    │ │
│*│ │ Concepts for Engineering Emergence in Systems of   │ │
│*│ │ Systems.” In Proceedings of the 12th Annual System │ │
│*│ │ of Systems Engineering Conference, IEEE, pp. 1-6.  │ │
│*│ │ https://ieeexplore.ieee.org/abstract/document/7994977
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, authentication system;                   │ │
│*│ │ coordination, event; ENSURE condition;             │ │
│*│ │ event sharing                                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 6 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
