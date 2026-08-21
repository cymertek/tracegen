/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 11. Model of Publish Subscribe             │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of asynchronous             │ │
│*│ │ coordination to get all valid permutations of      │ │
│*│ │ coordinated events.                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a model of a Publish-Subscribe             │ │
│*│ │ architecture. A Publisher sends a notification to  │ │
│*│ │ all active Subscribers when new information is     │ │
│*│ │ available.                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 7: Publish/Subscribe architecture" from   │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, publish subscribe architecture;          │ │
│*│ │ coordination, asynchronous; isomorphism            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ │ Scope 2: 68 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 6309 traces in approx. 10.2 min.          │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Publish_Subscribe

ROOT Publisher: 	Register
					(+ 	 <2 .. 3 + $$scope * 2> ( Register | Unsubscribe | Send )  +) 
/* 	Iteration_scope <2 .. 3 + $$scope * 2> is needed to provide enough events for 
	coordination, since each Client has Register/Unsubscribe event pair, 
    plus some Receive events  */

BUILD{
    /* The Register and Unsubscribe events should be balanced  */
    ENSURE #Register == #Unsubscribe;

    ENSURE FOREACH $u: Unsubscribe 	#Register BEFORE $u > #Unsubscribe BEFORE $u;
    
	/* 	Publisher will Send only if there is at least one active Client.
    	This condition is specified with ENSURE. */

	ENSURE FOREACH $s: Send 	#Register BEFORE $s > #Unsubscribe BEFORE $s;    
    };

Client: Register (* Receive *) Unsubscribe;

ROOT Subscribers: {+ Client +};

/****** Coordination between Publisher and Subscribers ******/
/* The ordering of composition operations is important, since Register and 
	Unsubscribe events are used to coordinate Send/Receive between  
    Publisher and Client. 
    
    First, we do SHARE ALL for Register events,
    next will try all valid permutations of Register/Unsubscribe,
    and then proceed with further coordination of Send/Receive,
    using the shared Register and Unsubscribe events as pivots 
    to coordinate Send events for each Client */

	/* Need to try all possible permutations of Register/Unsubscribe pairs, 
        hence the use of <!> event reshuffling */
COORDINATE 		$r1: Register FROM Publisher,
			<!> $r2: Register FROM Subscribers
	DO 	SHARE $r1 $r2; OD;

COORDINATE 		$u1: Unsubscribe FROM Publisher,
			<!> $u2: Unsubscribe FROM Subscribers
	DO 	SHARE $u1 $u2; OD;

/* the following coordination is performed 
	for each valid permutation of Register/Unsubscribe */
COORDINATE $client: Client FROM Subscribers
	DO COORDINATE 	$reg: Register 		FROM $client,
					$uns: Unsubscribe 	FROM $client

		/* For Send event selection to coordinate with a particular 
        	Client event, the SUCH THAT thread condition is used.
            Client will Receive all and only Send between his Register and Unsubscribe */
		DO COORDINATE 	$r: Receive FROM $client,
						$s: Send 	FROM Publisher
							SUCH THAT $s AFTER $reg AND $s BEFORE $uns

            /* Register and Unsubscribe events have been shared and now can be used
                to select appropriate Receive events from the Client and 
                Send events from the Publisher for coordination */

			DO ADD $s PRECEDES $r; OD;
		OD;
	OD;

/**** A query  ******/
/* It might be interesting to find out whether there are 
	Send events received by several Clients.
	MARK traces containing such event configuration, and place 
    annotation pointing to the Send event of interest*/
COORDINATE  $s: Send 
DO
	IF (#Receive FOLLOWS $s > 1) THEN 
		MARK;
		ADD SAY("this Send is received by " #Receive FOLLOWS $s " Clients")
			PRECEDES $s;
	FI;
OD;
