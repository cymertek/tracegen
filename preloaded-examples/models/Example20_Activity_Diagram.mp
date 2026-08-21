/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 20. Model of Activity Diagram              │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show how to extract Activity Diagrams of root   │ │
│*│ │ events in a schema.                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates how to use "SHOW ACTIVITY  │ │
│*│ │ DIAGRAM" to display events as a flowcharts similar │ │
│*│ │ to a Unified Modeling Language (UML) or Systems    │ │
│*│ │ Modeling Language (SysML) activity diagram. These  │ │
│*│ │ activity diagrams are projected from grammar rules │ │
│*│ │ and do not show interactions between activity      │ │
│*│ │ diagrams (coordination or share constraints). They │ │
│*│ │ may be useful for validating manually constructed  │ │
│*│ │ activity models used as source data for building   │ │
│*│ │ the MP model or just for representing the essence  │ │
│*│ │ of the text grammar rule as a graphic. Behavior    │ │
│*│ │ constraints like ENSURE can only be included as    │ │
│*│ │ comments. For concurrent events, MP activity       │ │
│*│ │ diagrams use abbreviations of set iterations in    │ │
│*│ │ the bars to convey iteration. As MP activity       │ │
│*│ │ diagrams are just a superficial approximation of   │ │
│*│ │ the behavior set specified in MP, they should be   │ │
│*│ │ used just as a summary view.                       │ │
│*│ │                                                    │ │
│*│ │ The Car Race schema is used to illustrate activity │ │
│*│ │ diagrams for Cars, Car, and Judge. Since these are │ │
│*│ │ summary views that have the same content for every │ │
│*│ │ trace, they may be put instead on a separate page  │ │
│*│ │ called a global view by using the keyword GLOBAL   │ │
│*│ │ just before the SHOW command.                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 51: Activity diagram of a root event"     │ │
│*│ │    from Auguston, M. "Monterey Phoenix System and  │ │
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
│*│ │ graph, activity diagram; graph, flowchart;         │ │
│*│ │ UML diagram, activity; SysML diagram, activity     │ │
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

SCHEMA Car_Race_Activity_Diagrams

Car:    Start 
        (* drive_lap *) 
        /* not necessary all cars will finish */
        ( finish [ winner ] | break) ;

ROOT Cars:	{+ Car +}

			BUILD{
				/* everybody who finishes drives the same number of laps */
				ENSURE FOREACH DISJ $c1: Car, $c2: Car 
						(#finish FROM $c1 == 1 AND #finish FROM $c2 == 1 -> 
						 #drive_lap FROM $c1 == #drive_lap FROM $c2)
                
						AND
					/* if it breaks, then earlier */
						(#finish FROM $c1 == 1 AND #break FROM $c2 == 1 -> 
						 #drive_lap FROM $c1 >= #drive_lap FROM $c2);
					
				/* there always will be at most one winner */
				ENSURE #winner <= 1;
			
				/* if at least one car finishes, there should be a winner */
				ENSURE #finish > 0 -> #winner > 0;
			};

ROOT Judge:		provide_start_signal 
				watch  
				(* finish *);

/* one-many coordination can be done with nested COORDINATE */
COORDINATE	$a: provide_start_signal	FROM Judge
	DO 	COORDINATE  $b: Start FROM Cars
			DO ADD $a PRECEDES $b; OD;
	OD;
	
Cars, Judge SHARE ALL finish;

/* 	now when the ordering of finish events is ensured 
    (because they are ordered in the Judge root traces), 
  	we can state: the winner is the car which finishes first */
COORDINATE $w: winner
	DO ENSURE #finish BEFORE $w == 1; OD;

/* this is an example of trace annotation with data 
    specific for the trace */

IF #finish == #Car THEN SAY("All cars have finished");
ELSE 			SAY( #finish " cars from " #Car 
                    " have finished");
FI;

/*	Uncomment the GLOBAL keyword below to move the activity diagrams 
	to the global view. Then click on the Global View button at the 
    top of the navigation pane (upper right ) to open the global view.*/
	
/*GLOBAL*/ 

SHOW ACTIVITY DIAGRAM Cars, Car, Judge;



