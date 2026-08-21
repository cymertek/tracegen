/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 05. Model of Car Race                      │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate                                      │ │
│*│ │ 1) one-to-many event coordination and              │ │
│*│ │ 2) trace annotation.                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model of a car race ties the number of Cars   │ │
│*│ │ in the race to the scope (running at scope 1 will  │ │
│*│ │ have one Car in the race, scope 2 will have two    │ │
│*│ │ Cars in the race, etc.). A single Judge signals    │ │
│*│ │ the start of the race, watches the race, and       │ │
│*│ │ observes the finish of the race. Ordering of       │ │
│*│ │ selected events in concurrent threads can be       │ │
│*│ │ modeled by coordinating them with event sequence,  │ │
│*│ │ allowing constraints such as "the winner is the    │ │
│*│ │ car that finishes first." One-to-many coordination │ │
│*│ │ can be accomplished using nested COORDINATE        │ │
│*│ │ statements. This example illustrates that there    │ │
│*│ │ are different coordination patterns that can be    │ │
│*│ │ used to shape interactions between events in       │ │
│*│ │ different roots. It also illustrates how traces    │ │
│*│ │ can be automatically annotated using SAY           │ │
│*│ │ statements.                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 6: Car race model" from Auguston, M.      │ │
│*│ │ "Monterey Phoenix System and Software Architecture │ │
│*│ │ and Workflow Modeling Language Manual"             │ │
│*│ │ (Version 4). 2020. Available online:               │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, car race; event sharing;                 │ │
│*│ │ coordination, one-to-many;                         │ │
│*│ │ coordination, nested composition; SAY statement;   │ │
│*│ │ BUILD block; predicate logic; trace annotation     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 30 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 236 traces in less than 1.5 sec.          │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Car_Race

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
			}
;

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
