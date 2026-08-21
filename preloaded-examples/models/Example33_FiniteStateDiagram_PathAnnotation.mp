/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 33. Model of Finite State Diagram with     │ │
│*│ │ Path Annotation                                    │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to                              │ │
│*│ │ 1) model the behavior of a finite state diagram    │ │
│*│ │    and                                             │ │
│*│ │ 2) generate event traces as annotated paths        │ │
│*│ │    through the diagram.                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The following MP schema models the behavior of a   │ │
│*│ │ finite state diagram with a single state loop      │ │
│*│ │ (S3 with a) and nondeterministic transitions       │ │
│*│ │ (from S1 with symbol a). In addition, it contains  │ │
│*│ │ MP code for visualizing event traces as paths in   │ │
│*│ │ the diagram (views of the event traces).           │ │
│*│ │                                                    │ │
│*│ │ Finite state transition diagrams are a popular     │ │
│*│ │ technique for modeling system behaviors. The       │ │
│*│ │ following example provides a template that can be  │ │
│*│ │ applied to many similar finite state diagram       │ │
│*│ │ models.                                            │ │
│*│ │                                                    │ │
│*│ │ The finite state transition diagram:               │ │
│*│ │    Start -> S1                                     │ │
│*│ │    S1 -> a -> S3                                   │ │
│*│ │    S1 -> a -> S4                                   │ │
│*│ │    S1 -> b -> S4                                   │ │
│*│ │    S2 -> b -> S1                                   │ │
│*│ │    S2 -> End                                       │ │
│*│ │    S3 -> a -> S3                                   │ │
│*│ │    S3 -> b -> S4                                   │ │
│*│ │    S4 -> a -> S2                                   │ │
│*│ │                                                    │ │
│*│ │ The main ideas are:                                │ │
│*│ │    - The modeling of the state diagram includes    │ │
│*│ │      state visits and actions triggering state     │ │
│*│ │      transitions. Only paths starting with Start   │ │
│*│ │      and ending with End are valid.                │ │
│*│ │    - Behavior of each state Si is represented by a │ │
│*│ │      separate root event Si_behavior.              │ │
│*│ │    - Each transition in the diagram Si -> Sj is    │ │
│*│ │      modeled by a composite event Si_to_Sj.        │ │
│*│ │    - Event Si_to_Sj contains the symbol and/or     │ │
│*│ │      action triggering the transition.             │ │
│*│ │    - Events Si_to_Sj are shared by corresponding   │ │
│*│ │      state behavior roots.                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 26: Modeling finite state machine" from   │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, finite automaton;                        │ │
│*│ │ graph, finite state transition diagram;            │ │
│*│ │ path annotation                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and 2.                            │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 30 traces in approx. 9.4 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Finite_State_Diagram_with_Path_Annotation

S1_to_S3: a;
S1_to_S4: (a | b);

ROOT S1_behavior:  	Start S1 
					(* (S1_to_S3 | S1_to_S4) S2_to_S1 S1 *) 
					(S1_to_S3 | S1_to_S4);

S2_to_S1: b;

ROOT S2_behavior:  	(* S4_to_S2 S2 S2_to_S1  *) 
					S4_to_S2 S2 End;

S1_behavior, S2_behavior SHARE ALL S2_to_S1;

/* coordination should be done as soon as possible,
	in order to prune the search, 
	but only after both root S1_behavior and S2_behavior 
	traces are available */

S3_to_S3: a;
S3_to_S4: b;

ROOT S3_behavior: (* 	S1_to_S3 S3 
    					(* S3_to_S3 S3 *)
    					S3_to_S4 			*) ;

S3_behavior, S1_behavior SHARE ALL S1_to_S3;

S4_to_S2: a;

ROOT S4_behavior: (* (S1_to_S4 | S3_to_S4) S4 
    					 S4_to_S2 *) ;

S4_behavior, S1_behavior SHARE ALL S1_to_S4;
S4_behavior, S2_behavior SHARE ALL S4_to_S2;
S4_behavior, S3_behavior SHARE ALL S3_to_S4;

SAY("The path: ");
/* Sort state visits and transition events according to the BEFORE relation and then show them */
COORDINATE 	<SORT> $a: (S1 | S2 | S3 | S4 | a | b | Start | End)
	DO SAY($a); OD;
