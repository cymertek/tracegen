/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 23. Model of Car Race with Local Graph     │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the construction of a local graph   │ │
│*│ │ on a trace.                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Graphs are "entity-relation" models extracted from │ │
│*│ │ event traces in order to visualize certain         │ │
│*│ │ dependencies within the trace. A graph is          │ │
│*│ │ constructed from nodes and edges connecting the    │ │
│*│ │ nodes. Usually a node represents some event in the │ │
│*│ │ trace and an edge visualizes a dependency between  │ │
│*│ │ events. Edges can be directed arrows or undirected │ │
│*│ │ lines. This schema builds upon the Car Race        │ │
│*│ │ behavior model first introduced in Example 6 from  │ │
│*│ │ the manual to provide an example of a graph        │ │
│*│ │ construction on a trace based on information       │ │
│*│ │ contained in the trace (in this case, the graph    │ │
│*│ │ represents the trace of events for the winning     │ │
│*│ │ car).                                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 41: Graph extracted from a particular     │ │
│*│ │    event trace (local trace view)" from            │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Example 6: Car race model" from Auguston, M.      │ │
│*│ │    "Monterey Phoenix System and Software           │ │
│*│ │    Architecture and Workflow Modeling Language     │ │
│*│ │    Manual" (Version 4). 2020. Available online:    │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, car race; graph, local                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 30 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 236 traces in approx. 1.5 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Car_Race_with_Local_Graph

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

