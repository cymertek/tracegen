/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of a Simple Stopwatch, Integrated States and │ │
│*│ │   Transitions                                      │ │
│*│ │  Created by Kristin Giammarco and Pamela Dyer      │ │
│*│ │   in June, 2022.                                   │ │
│*│ │  Modified by Pamela Dyer in July, 2022.            │ │
│*│ │  Edited by Pamela Dyer in August, 2022.            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate how to construct a state diagram in  │ │
│*│ │ MP based on an example model that comes with the   │ │
│*│ │ 3DS Magic System of Systems Architect (MSOSA) tool │ │
│*│ │ (formerly No Magic's Cameo tool), and use MP's     │ │
│*│ │ event trace generator to trace through all paths   │ │ 
│*│ │ of the state diagram at Scope 1.                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ One of the tutorials that accompanies the MSOSA    │ │
│*│ │ tool shows how to build an executable state diagram│ │
│*│ │ of a simple stopwatch. Consisting of only four 	 │ │
│*│ │ states and nine transitions, the model is ideal 	 │ │
│*│ │ for learning the process. This MP schema aims to   │ │
│*│ │ recreate that MSOSA model, here using events to    │ │
│*│ │ represent alternating states and transitions. The  │ │
│*│ │ states and transitions are placed in a single root.│ │
│*│ │ Event triples of state-transition-state are   	 │ │
│*│ │ extracted from the event traces and accumulated in │ │
│*│ │ a global graph, which is the state diagram.        │ │
│*│ │ A table is printed on each trace to illustrate the │ │
│*│ │ state-transition-state triples contributed by that │ │
│*│ │ trace. This is a useful table for debugging as     │ │
│*│ │ the model is being built. To ensure the correct    │ │
│*│ │ state diagram here, remember to alternate          │ │
│*│ │ consistently between states and transitions.       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Magic Model Analyst 2021x LTR User Guide," from   │ │
│*│ │ No Magic, Inc., a Dassault Systèmes company. 2020. │ │
│*│ │ Stopwatch model sample pp. 530-581.                │ │
│*│ │ Available online:                                  │ │
│*│ │ https://docs.nomagic.com/display/MSI190SP4/Executing+the+StopWatch+class
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stopwatch; coordination, event;          │ │
│*│ │ graph, finite state transition diagram;            │ │
│*│ │ event traces, compact; tables, for debugging        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 42 traces in approx. 1 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA StopWatch_State_Diagram_Single_Root

ROOT StopWatch: 

	  	START
		initialize /* an empty transition in 3DS tutorial */
      	
		ready
        start  
        running	

		/*transition to self*/
		(* ( at_1s running 					| 
        /*transition to paused and back to running*/ 
             split paused unsplit running 	) 
         *)
		/*transition to paused and then to stopped*/
		[ split paused ]

		stop 
		stopped

		/*option to reset and run more times */
		(* 	reset
            ready
        	start
        	running	
		/*transition to self*/
			(* ( at_1s running 					| 
             split paused unsplit running 	) 
         	*)
			[ split paused ]

			stop
        	stopped
        *)

		stop
        END
;


/* 	Create a diagnostic table on each event trace showing 
	the state-transition-state triples used to graph the 
    state diagram */

TABLE StatechartDiagnosticTable 
		{	TITLE ("Statechart Triples from This Trace");
    		TABS 	string state1,
					string transition,
					string state2;	
		};

/*	The following command empties the table before
	populating it for each trace */
CLEAR StatechartDiagnosticTable;


/* Build the state diagram*/

GRAPH StateDiagram{ TITLE("StopWatch State Diagram"); };

COORDINATE 
	<CUT_END>   $state1:
					( START | ready | running | paused | stopped | END), 

			 	$transition:
     				( initialize | start | at_1s | split | unsplit | 
                        stop | reset ),   

	<CUT_FRONT> $state2:
				 	( START | ready | running | paused | stopped | END)  

	 DO	WITHIN StateDiagram { ADD 	LAST ($state1) 
        							ARROW($transition) 
        							LAST ($state2); 
							 }; 

	/* 	Populate the diagnostic table with each state1-transition-state2 
    	triple */ 		
	StatechartDiagnosticTable <|
							state1: SAY($state1),
							transition: SAY($transition),
							state2: SAY($state2) ;
	 OD; 

/* ENSURE #at_1s >= 1; */

/* Print the tables and graphs */
SHOW StatechartDiagnosticTable;

GLOBAL

SHOW StateDiagram;  

/* Comment in the following to see the activity diagram for the Stopwatch */
/*SHOW ACTIVITY DIAGRAM StopWatch;  */