/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 04. Model of Stack Behavior                │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of the ENSURE condition     │ │
│*│ │ containing an example Boolean expression.          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The event trace is a set of events and the Boolean │ │
│*│ │ expressions in MP can embrace the traditional      │ │
│*│ │ predicate calculus notation. A set of behaviors    │ │
│*│ │ (event traces) may be defined by the event grammar │ │
│*│ │ rules, composition operations, and some additional │ │
│*│ │ constraints – ENSURE conditions.                   │ │
│*│ │                                                    │ │
│*│ │ Stack implements the “last in, first out” behavior │ │
│*│ │ for storing/retrieving elements. It is assumed     │ │
│*│ │ that initially Stack is empty.                     │ │
│*│ │                                                    │ │
│*│ │ This rule specifies the behavior of a stack in     │ │
│*│ │ terms of stack operations push and pop. The BUILD  │ │
│*│ │ block associated with a root or composite event    │ │
│*│ │ contains composition operations performed when     │ │
│*│ │ event trace segment representing the behavior of   │ │
│*│ │ that root or composite is generated. The ENSURE    │ │
│*│ │ Boolean expression provides a condition that each  │ │
│*│ │ valid trace should satisfy. The domain of the      │ │
│*│ │ universal quantifier is the set of all pop events  │ │
│*│ │ inside Stack. The FROM Stack part is optional, by  │ │
│*│ │ default it is assumed to be FROM THIS.             │ │
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
│*│ │ "Example 5: Stack behavior model" from             │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stack; ENSURE condition;                 │ │
│*│ │ Boolean expression; isomorphism                    │ │
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
/* If an element is retrieved, it should have been stored before */
ENSURE FOREACH $x: pop FROM Stack
( #pop BEFORE $x < #push BEFORE $x );
};
