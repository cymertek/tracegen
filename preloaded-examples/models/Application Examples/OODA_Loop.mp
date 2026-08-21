/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of OODA Loop                                 │ │
│*│ │  Created by Pamela Dyer, Kristin Giammarco, and    │ │
│*│ │   Shelley Gallup in July, 2022.                    │ │
│*│ │  Modified by Pamela Dyer in August, 2022.          │ │
│*│ │  Edited by Pamela Dyer and Kristin Giammarco in    │ │
│*│ │   October, 2022.                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To use MP to model an adaptation of the well-known │ │
│*│ │ Observe-Orient-Decide-Act cycle (OODA Loop), and to│ │
│*│ │ generate accompanying state diagrams that visually │ │
│*│ │ demonstrate this process.                          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ In this MP model, the four main OODA Loop steps are│ │
│*│ │ defined in one root as the States, and then all    │ │
│*│ │ events representing forward flow or feedback that  │ │
│*│ │ connects states together are defined in a second   │ │
│*│ │ root as the Transitions. The States root below     │ │
│*│ │ contains outer loop(s) of Observe-Orient-Decide-Act│ │
│*│ │ and inner loop(s) of Observe-Orient-Decide. The    │ │
│*│ │ <1..3> gives the option of 1, 2, or 3 inner loops  │ │
│*│ │ of Observe-Orient-Decide within each outer loop of │ │
│*│ │ Observe-Orient-Decide-Act. The last four COORDINATE│ │
│*│ │ statements below properly connect States to the    │ │
│*│ │ appropriate Transitions - if Observe is the event  │ │
│*│ │ immediately following Decide in the States root,   │ │
│*│ │ then "decide_to_observe_feedback" is the Transition│ │
│*│ │ between them, for example. It is also important to │ │
│*│ │ note that the state diagram produced at Scope 1    │ │
│*│ │ does not show the one portion of moving from Act   │ │
│*│ │ back to Observe. This is because only one full     │ │
│*│ │ cycle of Observe-Orient-Decide-Act is allowed in   │ │
│*│ │ this model at Scope 1, per the iteration structure.│ │
│*│ │ Starting at Scope 2 and above, multiple full cycles│ │
│*│ │ can be seen in the generated traces, and therefore │ │
│*│ │ the full state diagram is also visible.            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Osinga, Frans P.B. Science, Strategy and War: The  │ │
│*│ │ Strategic Theory of John Boyd. London ; New York : │ │
│*│ │ Routledge, 2007.                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, OODA Loop; scope, local;                 │ │
│*│ │ coordination, event; coordination, conditional;    │ │
│*│ │ graph, finite state transition diagram;            │ │
│*│ │ tables, for debugging; graph, activity diagram     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 12 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 39 traces in approx. 1.2 min.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA OODA_Loop


ROOT States:        (+  (+ <1..3> Observe
                                  Orient
                                  Decide  +)
                                  Act         +)
;

ROOT Transitions:   (+  observe_to_orient
                        orient_to_decide
                        (* decide_to_observe_feedback 
                           observe_to_orient
                           orient_to_decide            *)
                        decide_to_act
                        [ act_to_observe_feedback ]        +)
;


COORDINATE  $x: Observe, 
            $y: observe_to_orient
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: observe_to_orient, 
            $y: Orient
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: Orient, 
            $y: orient_to_decide
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: orient_to_decide,
            $y: Decide
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: Decide
     SUCH THAT #Act FOLLOWS $x == 1,
            $y: decide_to_act
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: decide_to_act,
            $y: Act
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: Decide
     SUCH THAT #Observe FOLLOWS $x == 1,
            $y: decide_to_observe_feedback
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: decide_to_observe_feedback,
            $y: Observe
     SUCH THAT #Decide PRECEDES $y == 1
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: Act
     SUCH THAT #Observe FOLLOWS $x == 1,
            $y: act_to_observe_feedback
    DO ADD  $x PRECEDES $y; OD;

COORDINATE  $x: act_to_observe_feedback,
            $y: Observe
     SUCH THAT #Act PRECEDES $y == 1
    DO ADD  $x PRECEDES $y; OD;


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


/*  Build the state diagram */

GRAPH StateDiagram{ TITLE("OODA Loop State Diagram"); };

COORDINATE 
	<CUT_END>   $state1:
					( Observe | Orient | Decide | Act ), 

			 	$transition:
     				( observe_to_orient | orient_to_decide | decide_to_act | 
                         act_to_observe_feedback | decide_to_observe_feedback ),

	<CUT_FRONT> $state2:
				 	( Observe | Orient | Decide | Act )

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

SHOW ACTIVITY DIAGRAM States;

SHOW StateDiagram;  
