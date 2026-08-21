/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 10. Model of Pipe Filter                   │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to conduct a queries for model  │ │
│*│ │ properties using automatic trace annotation.       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a behavior model of a pipe/filter          │ │
│*│ │ architecture with two filters. The assumptions are │ │
│*│ │ as follows:                                        │ │
│*│ │    1) not all items sent by Producer will be       │ │
│*│ │       received by Consumer,                        │ │
│*│ │    2) after a message has been sent, it cannot be  │ │
│*│ │       sent repeatedly,                             │ │
│*│ │    3) a received message can stay in the Filter    │ │
│*│ │       for a while before being sent (if at all).   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 12: Pipe/Filter architecture model" from  │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, pipe filter architecture;                │ │
│*│ │ query, trace annotation; isomorphism               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 19 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 121 traces in less than 1 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Pipe_Filter

ROOT Producer: (* send *);

ROOT Filter1: (* receive (* send *) *)
/* Filter can send only after receive */
    BUILD { /* can send only what has been received */
        ENSURE FOREACH $s: send 
        	(#receive BEFORE $s > #send BEFORE $s);

        /* not everything received will be sent */
		IF #send != #receive THEN 
        	SAY("some messages have been lost in Filter1" ); FI;
	};

COORDINATE  $s: send    FROM Producer,
            $r: receive FROM Filter1
    DO ADD $s PRECEDES $r; OD;

ROOT Filter2: (* receive (* send  *) *)
/* Filter can send only after receive */
    BUILD { /* can send only what has been received */
        ENSURE FOREACH $s: send 
        	(#receive BEFORE $s > #send BEFORE $s);
        
        /* not everything received will be sent */
		IF #send != #receive THEN 
        	SAY("some messages have been lost in Filter2" ); FI;
	};

COORDINATE  $s: send    FROM Filter1,
            $r: receive FROM Filter2
    DO ADD $s PRECEDES $r; OD;

ROOT Consumer: (* receive *);

COORDINATE  $s: send    FROM Filter2,
            $r: receive FROM Consumer
    DO ADD $s PRECEDES $r; OD;

IF #receive FROM Consumer != #send FROM Producer THEN
	SAY( #send FROM Producer - #receive FROM Consumer  
        " messages did not reach Consumer");
	MARK;
FI;
