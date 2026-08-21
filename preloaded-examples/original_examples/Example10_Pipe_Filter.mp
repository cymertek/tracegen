/*  Example10_Pipe_Filter.mp 
    pipe/filter architecture model with 2 filters

    assumptions: 
    	1) not all items sent by Producer will be received by Consumer, 
        2) after a message has been sent, it cannot be send repeatedly,
        3) received message can stay in the Filter for while, 
        	before being sent (if at all).
*/

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