/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of a Simple Stopwatch, Separated States and  │ │
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
│*│ │ states and transitions are placed in separate      │ │
│*│ │ coordinated roots, resulting in two swim lanes in  │ │
│*│ │ each event trace. This makes for more compact event│ │
│*│ │ traces that are a little easier to read than having│ │
│*│ │ every event within one root, for example.          │ │
│*│ │ Event triples of state-transition-state are   	 │ │
│*│ │ extracted from the event traces and accumulated in │ │
│*│ │ a global graph, which is the state diagram.        │ │
│*│ │ A table is printed on each trace to illustrate the │ │
│*│ │ state-transition-state triples contributed by that │ │
│*│ │ trace. This is a useful table for debugging as     │ │
│*│ │ the model is being built. To ensure the correct    │ │
│*│ │ state diagram here, it is important to not only    │ │
│*│ │ remember to alternate consistently between states  │ │
│*│ │ and transitions but to alternate consistently 	 │ │
│*│ │ states in one root and transitions in the other.   │ │
│*│ │ That is, do not place a transition in the state    │ │
│*│ │ root, or a state in the transition root.           │ │
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
│*│ │ event traces, compact; tables, for debugging       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 42 traces in approx. 1.86 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA StopWatch_States_and_Transitions


ROOT States:  /* In this root, transitions in between the states are 
                 noted as comments */

        START
        /*initialize*/
      	
        ready
        /*start*/ 
        running	

        /*transition to self*/
        (* ( /*at_1s*/ running 					      |  
        /*transition to paused and back to running*/ 
             /*split*/ paused /*unsplit*/ running 	) 
         *)
        /*transition to paused and then to stopped*/
        ( /*split*/ paused /*pause_stop*/ | /*running_stop*/ )

        stopped
                

        /*option to reset and run more times */
        (*  /*reset*/
            ready
            /*start*/
            running	
        (* ( /*at_1s*/ running 					       | 
             /*split*/ paused /*unsplit*/ running 	) 
         *)
        ( /*split*/ paused /*pause_stop*/ | /*running_stop*/ )

        stopped
        *)

        /*end_stop*/
        END
;


ROOT Transitions:  /* In this root, states in between the transitions are 
                      noted as comments */

        /*START*/
        initialize /* an empty transition in 3DS tutorial */
      	
        /*ready*/
        start  
        /*running*/

        /*transition to self*/
        (* ( at_1s /*running*/						  | 
        /*transition to paused and back to running*/ 
             split /*paused*/ unsplit /*running*/	) 
         *)
        /*transition to paused and then to stopped*/
        ( split /*paused*/ pause_stop | running_stop )

        /*stopped*/

        /*option to reset and run more times */
        (*  reset
            /*ready*/
            start
            /*running*/
            (* ( at_1s /*running*/ 					   | 
                 split /*paused*/ unsplit /*running*/ 	) 
            *)
            ( split /*paused*/ pause_stop | running_stop )

            /*stopped*/
        *)

        end_stop
        /*END*/
;



/* 	Coordinate statements to zip together states and transitions from 
	separate roots */

COORDINATE $a: START, $b: initialize
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: ( initialize | reset ), $b: ready
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: ready, $b: start
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: ( start | unsplit | at_1s ), $b: running
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: running, $b: ( split | running_stop | at_1s ) 
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: split, $b: paused
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: paused, $b: ( unsplit | pause_stop )
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: ( running_stop | pause_stop ), $b: stopped
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: stopped, $b: ( reset | end_stop )
	DO ADD $a PRECEDES $b ; OD;

COORDINATE $a: end_stop, $b: END
	DO ADD $a PRECEDES $b ; OD;






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
					( START | ready | running | paused | stopped | END ), 

			 	$transition:
     				( initialize | start | at_1s | split | unsplit | 
                        pause_stop | running_stop | end_stop | reset ),

	<CUT_FRONT> $state2:
				 	( START | ready | running | paused | stopped | END )  

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

/* Print the tables and graphs */

SHOW StatechartDiagnosticTable;

GLOBAL

SHOW StateDiagram;  

/* 	Comment in the following to see separate activity diagrams for the 
	Transitions and the States */
/*  SHOW ACTIVITY DIAGRAM Transitions, States; */
