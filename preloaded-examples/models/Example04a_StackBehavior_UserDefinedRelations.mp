/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 04a. Model of Stack Behavior               │ │
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
│*│ │    specification, and                              │ │
│*│ │ 3) demonstrate a user-defined relation             │ │
│*│ │    "Paired_with" to show which "push" events are   │ │
│*│ │    paired with which "pop" events.                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model is an expansion on Example 04. Model of │ │
│*│ │ Stack Behavior.                                    │ │
│*│ │                                                    │ │
│*│ │ The event trace is a set of events and the Boolean │ │
│*│ │ expression constructs in MP can support the        │ │
│*│ │ traditional first order predicate calculus         │ │
│*│ │ notation.                                          │ │
│*│ │                                                    │ │
│*│ │ A set of behaviors (event traces) may be defined   │ │
│*│ │ by the event grammar                               │ │
│*│ │ rules, composition operations, and some additional │ │
│*│ │ constraints – ENSURE conditions.                   │ │
│*│ │                                                    │ │
│*│ │ This rule specifies the behavior of a stack in     │ │
│*│ │ terms of stack operations push and pop. It is      │ │
│*│ │ assumed that initially Stack is empty. The BUILD   │ │
│*│ │ block associated with a root or composite event    │ │
│*│ │ contains composition operations performed when     │ │
│*│ │ event trace segment representing the behavior of   │ │
│*│ │ that root or composite is generated.               │ │
│*│ │                                                    │ │
│*│ │ The ENSURE Boolean expression provides a condition │ │
│*│ │ that each valid trace should satisfy. The domain   │ │
│*│ │ of the universal quantifier is the set of all pop  │ │
│*│ │ events inside Stack trace. The FROM Stack part is  │ │
│*│ │ optional, by default it is assumed to be FROM      │ │
│*│ │ THIS.                                              │ │
│*│ │                                                    │ │
│*│ │ The function #pop BEFORE $x yields the number of   │ │
│*│ │ pop events preceding $x. The set of valid event    │ │
│*│ │ traces specified by this schema contains only      │ │
│*│ │ traces that satisfy the constraint. This example   │ │
│*│ │ presents a filtering operation as yet another kind │ │
│*│ │ of behavior composition, and demonstrates an       │ │
│*│ │ example of combining imperative (event grammar)    │ │
│*│ │ and declarative (Boolean expressions) constructs   │ │
│*│ │ for behavior specification.                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 17: Stack behavior model" from            │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stack; user-defined relation;            │ │
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

SCHEMA Stack_Behavior

ROOT Stack: (* ( push | pop ) *)
		BUILD { 
            /* if an element is retrieved, it should have been stored before */
            ENSURE FOREACH $x: pop FROM Stack
					( #pop BEFORE $x < #push BEFORE $x );

        /* The following composition operation establishes push/pop pairs
            in the Stack behavior. For each 'pop' the closest in time 
            preceding 'push' is selected, unless it has been already 
            consumed by another 'pop' */

            COORDINATE  $get: pop 
                DO COORDINATE <REVERSE> $put: push 
                                        SUCH THAT $put BEFORE $get 
                    DO 	IF 	NOT ( EXISTS $g: pop $put Paired_with $g OR
                                  EXISTS $p: push $p Paired_with $get 	)
                        THEN ADD $put Paired_with $get; FI;
                    OD;
                OD;
        };/* end BUILD for Stack */

