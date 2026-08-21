/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 04b. Model of Queue Behavior               │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To                                                 │ │
│*│ │ 1) present use of BUILD block as a filtering       │ │
│*│ │    operation on event trace segments,              │ │
│*│ │ 2) demonstrate the combination of imperative       │ │
│*│ │    (event grammar) and declarative (Boolean        │ │
│*│ │    expressions) constructs for behavior            │ │
│*│ │    specification,                                  │ │
│*│ │ 3) demonstrate a user-defined relation             │ │
│*│ │    "Paired_with" to show which "enqueue" events    │ │
│*│ │    are paired with which "dequeue" events, and     │ │
│*│ │ 4) present the concept of isomorphism with respect │ │
│*│ │    to models in MP.                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model is isomorphic to Example 04a. Model of  │ │
│*│ │ Stack Behavior.                                    │ │
│*│ │                                                    │ │
│*│ │ The event trace is a set of events and the Boolean │ │
│*│ │ expression constructs in MP can support the        │ │
│*│ │ traditional first order predicate calculus         │ │
│*│ │ notation.                                          │ │
│*│ │                                                    │ │
│*│ │ A set of behaviors (event traces) may be defined   │ │
│*│ │ by the event grammar rules, composition            │ │
│*│ │ operations, and some additional constraints –      │ │
│*│ │ ENSURE conditions.                                 │ │
│*│ │                                                    │ │
│*│ │ This rule specifies the behavior of a queue in     │ │
│*│ │ terms of queue operations enqueue and dequeue. It  │ │
│*│ │ is assumed that initially Queue is empty. The      │ │
│*│ │ BUILD block associated with a root or composite    │ │
│*│ │ event contains composition operations performed    │ │
│*│ │ when event trace segment representing the behavior │ │
│*│ │ of that root or composite is generated.            │ │
│*│ │                                                    │ │
│*│ │ The ENSURE Boolean expression provides a condition │ │
│*│ │ that each valid trace should satisfy. The domain   │ │
│*│ │ of the universal quantifier is the set of all      │ │
│*│ │ dequeue events inside Queue trace.                 │ │
│*│ │                                                    │ │
│*│ │ The function #dequeue BEFORE $x yields the number  │ │
│*│ │ of dequeue events preceding $x. The set of valid   │ │
│*│ │ event traces specified by this schema contains     │ │
│*│ │ only traces that satisfy the constraint. This      │ │
│*│ │ example presents a filtering operation as yet      │ │
│*│ │ another kind of behavior composition, and          │ │
│*│ │ demonstrates an example of combining imperative    │ │
│*│ │ (event grammar) and declarative (Boolean           │ │
│*│ │ expressions) constructs for behavior               │ │
│*│ │ specification.                                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 18: Queue behavior model" from            │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, queue; user-defined relation;            │ │
│*│ │ isomorphism                                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 7 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Queue_Behavior

ROOT Queue: (* ( enqueue | dequeue ) *)
	BUILD { 
        /* if an element is retrieved, it should have been stored before,
            this constraint is identical to Stack behavior constraint. */
        ENSURE FOREACH $x: dequeue 
				( #dequeue BEFORE $x < #enqueue BEFORE $x );

     /* The following composition operation establishes enqueue/dequeue pairs
     	in the Queue behavior. For each 'dequeue' the earliest in time 
     	preceding 'enqueue' is selected, unless it has been already 
        consumed by another 'dequeue' */
     
	COORDINATE  $get: dequeue 
		DO COORDINATE $put: enqueue 
                            SUCH THAT $put BEFORE $get 
			DO 	IF NOT ( EXISTS $g: dequeue $put Paired_with $g OR
						 EXISTS $p: enqueue $p Paired_with $get 	 )
				THEN ADD $put Paired_with $get; FI;
			OD;
		OD;
    };/* end BUILD for Queue */

