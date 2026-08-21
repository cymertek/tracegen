/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 38. Model of Merging Root Events to Reduce │ │
│*│ │ Run Time                                           │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to organize a hierarchy of      │ │
│*│ │ derivations in order to reduce run time for larger │ │
│*│ │ models.                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model has several interacting root events,    │ │
│*│ │ where roots B and C have several coordination      │ │
│*│ │ operations between them. These coordination        │ │
│*│ │ operations will be performed repeatedly each time  │ │
│*│ │ when derivation process backtracks and performs    │ │
│*│ │ new top-down pass through schema’s code for the    │ │
│*│ │ next trace derivation.                             │ │
│*│ │                                                    │ │
│*│ │ B and C have two coordination operations between   │ │
│*│ │ them: COORDINATE and SHARE ALL. To delegate this   │ │
│*│ │ "heavy" coordination to a separate derivation task │ │
│*│ │ we introduce a separate root event B_and_C to      │ │
│*│ │ encapsulate the trace segment derivation           │ │
│*│ │ (including the coordination) for B and C.          │ │
│*│ │                                                    │ │
│*│ │ Complex MP models may have large number of root    │ │
│*│ │ events with several coordination operations        │ │
│*│ │ performed on clusters of roots. This may be a      │ │
│*│ │ system architecture model with a large number of   │ │
│*│ │ actors (components) and interactions (connectors)  │ │
│*│ │ between them. The “layered derivation” strategy    │ │
│*│ │ implemented in MP may help to speed up the trace   │ │
│*│ │ derivation, and in many cases makes it possible to │ │
│*│ │ work with fairly large and complex MP models. The  │ │
│*│ │ idea is simple – organize the derivation as a      │ │
│*│ │ hierarchy of smaller derivations.                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 37: Merging root events model" from       │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ merging root events; reduce run time;              │ │
│*│ │ layered derivation                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and 2.                            │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 53 traces in less than 1 sec.             │ │
│*│ │ Scope 2: 1150 traces in less than 1 sec.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Merging_Root_Events_to_Reduce_Run_Time
ROOT A: (* ( work | send_to_B) *);
ROOT B: (*<1.. $$scope + 1>
( work | receive_from_A | send_to_C ) *);
COORDINATE $a: send_to_B,
$b: receive_from_A
DO ADD $a PRECEDES $b; OD;
ROOT C: (*<1.. $$scope + 1>
( work | receive_from_B | send_to_D ) *);
COORDINATE $a: send_to_C,
$b: receive_from_B
DO ADD $a PRECEDES $b; OD;
B, C SHARE ALL work;
ROOT D: (* (work | receive_from_C ) *);
COORDINATE $a: send_to_D,
$b: receive_from_C
DO ADD $a PRECEDES $b; OD;
