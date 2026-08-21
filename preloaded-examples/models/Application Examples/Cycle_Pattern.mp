/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Cycle Pattern                             │ │
│*│ │  Created by Kristin Giammarco on the 10th of       │ │
│*│ │     March, 2018.                                   │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate a cycle as a form of pattern that    │ │
│*│ │ can be modeled in MP, and to show how rule-based   │ │
│*│ │ comments can be added to the traces.               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The model below describes a cycle in terms of a    │ │
│*│ │ series of one or more steps, each step either      │ │
│*│ │ moving the system "forward" or "backward" as the   │ │
│*│ │ process unfolds. "Forward" and "backward" are      │ │
│*│ │ generic terms that may be substituted with         │ │
│*│ │ synonyms such as "up" and "down," "in" and "out",  │ │
│*│ │ "over" and "under", "increase" and "decrease",     │ │
│*│ │ etc., or discinyms (discipline-specific synonyms)  │ │
│*│ │ as they may appear in the preferred domain         │ │
│*│ │ taxonomy.                                          │ │
│*│ │                                                    │ │
│*│ │ IF and SAY statements are used here to add         │ │
│*│ │ commentary to the traces. A user may document the  │ │
│*│ │ "story" told by each trace separately, or use SAY  │ │
│*│ │ statements to incorporate notes about significant  │ │
│*│ │ events or event patterns directly into the event   │ │
│*│ │ traces. Users may reference this model when        │ │
│*│ │ looking to use SAY or IF statements to add notes   │ │
│*│ │ to their traces.                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Giammarco, Kristin, and Len Troncale. "Modeling    │ │
│*│ │ Isomorphic Systems Processes Using Monterey        │ │
│*│ │ Phoenix." Systems 6, no. 2 (2018): 18.             │ │
│*│ │ https://doi.org/10.3390/systems6020018             │ │
│*│ │ https://www.mdpi.com/2079-8954/6/2/18              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, cycle pattern; ENSURE condition;         │ │
│*│ │ IF statement; SAY statement; isomorphism           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 2 and 3. (Scope 1 generates zero    │ │
│*│ │ traces because of the ENSURE constraint.)          │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 0 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 40 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 2952 traces in approx. 2.9 sec.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Cycle_ISP_v2

ROOT Cycle:   	(+ Initial_condition 
			  		(+ ( Step_forward | Step_backward ) +)
				   End_condition +);

ENSURE #( Step_forward | Step_backward ) > 1;


                   
/*Check for Positive Reinforcement Template */
IF EXISTS DISJ $a:  Step_forward, $b: Step_forward  
			$a PRECEDES $b THEN 
				SAY("Positive Reinforcement Detected"); FI;

/*Check for Negative Reinforcement Template */
IF EXISTS DISJ $a:  Step_backward, $b: Step_backward  
			$a PRECEDES $b THEN 
				SAY("Negative Reinforcement Detected"); FI;

/*Check for Oscillation Template */
IF EXISTS  $a:  Step_forward, $b: Step_backward  
			$a PRECEDES $b  OR
			$b PRECEDES $a 	THEN 
				SAY("Oscillation Detected"); FI;

/*Note Lifecycle Completion */
COORDINATE $a: End_condition
	DO ADD SAY("Lifecycle Complete") PRECEDES $a; OD;

/*Check for Recycle Template */
IF #Initial_condition > 1 THEN 
				SAY("Recycle Detected"); FI;


