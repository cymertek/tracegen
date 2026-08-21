/* Example 32. Local graph within the event trace.
	run for scope 1 and up
------------------------------------------------*/
SCHEMA Car_Race

Car:    Start 
        (* drive_lap *) 
        ( finish [ winner ] | break);

ROOT Cars:	{+ Car +}
	BUILD{
	/* everybody who finishes drives the same number of laps */
		ENSURE FOREACH DISJ $c1: Car, $c2: Car 
			(#finish FROM $c1 == 1 AND #finish FROM $c2 == 1 -> 
				#drive_lap FROM $c1 == #drive_lap FROM $c2) AND
				/* if it breaks, then earlier */
			(#finish FROM $c1 == 1 AND #break FROM $c2 == 1 -> 
				#drive_lap FROM $c1 >= #drive_lap FROM $c2);
					
				/* there always will be at most one winner */
				ENSURE #winner <= 1;
			
				/* if at least one car finishes, there should be a winner */
ENSURE #finish > 0 -> #winner > 0;  };


ROOT Judge:	provide_start_signal 
				watch  
				(* finish *);

COORDINATE	$a: provide_start_signal	FROM Judge
	DO 	COORDINATE  $b: Start FROM Cars
			DO ADD $a PRECEDES $b; OD;
	OD;
Cars, Judge SHARE ALL finish;

COORDINATE $w: winner
	DO ENSURE #finish BEFORE $w == 1; OD;

/* =======================================================
  Here starts the trace view graph construction. 
  Operations are performed after a valid event trace has been 
  successfully derived. 
=========================================================*/
GRAPH Winner_trace {
  TITLE( "winner trace " trace_id " for scope " $$scope);};

/* We want to render a graph extracted from each valid event trace, 
so the graph is cleared before the trace processing starts. */

	COORDINATE $car_event: Car SUCH THAT #winner FROM $car_event > 0
		  DO 

/* the following WITHIN command provides a context for performing 
	operations on the Winner_trace graph */
WITHIN Winner_trace{
    Node$laps: NEW(#drive_lap FROM $car_event " laps");
    ADD NEW("Start") 	ARROW("followed by") 	Node$laps;
    ADD Node$laps 		ARROW("followed by") 	NEW("finish");
    ADD LAST("finish") 	ARROW("followed by") 	NEW("winner");
};  /* end of WITHIN Winner_trace  body */

	OD; /* end of Car loop */

SHOW Winner_trace;
CLEAR Winner_trace ;

