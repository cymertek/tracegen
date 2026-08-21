/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Knapsack Weight Limit                     │ │
│*│ │  Created by Mikhail Auguston in 2019.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the process of searching for all     │ │
│*│ │ optimal solutions in a certain scope, with a limit │ │
│*│ │ set for the weight of the knapsack.                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a case of well-known Knapsack Dynamic      │ │
│*│ │ Programming Problem. In general it is NP-hard and  │ │
│*│ │ NP-complete with respect to the number N of items  │ │
│*│ │ and to the weight limit W. It has been proven that │ │
│*│ │ the computational complexity is O(N * W)           │ │
│*│ │                                                    │ │
│*│ │ This example demonstrates MP template for          │ │
│*│ │ performing "brute force" search for all optimal    │ │
│*│ │ solutions within the given scope (certainly not    │ │
│*│ │ the optimal performance, but is acceptable for     │ │
│*│ │ relatively small N, in particular, it stabilizes   │ │
│*│ │ at scope 4).                                       │ │
│*│ │                                                    │ │
│*│ │ Ultimately, this model demonstrates using GLOBAL   │ │
│*│ │ limits to exhaustively calculate all the           │ │
│*│ │ combinations of items that can be put into a bag   │ │
│*│ │ to not exceed the weight limit. Users can          │ │
│*│ │ reference this model to learn about solving logic  │ │
│*│ │ problems with MP constraints.                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 47: “Brute force” search over the set of  │ │
│*│ │    traces for optimal value." from Auguston, M.    │ │
│*│ │    "Monterey Phoenix System and Software           │ │
│*│ │    Architecture and Workflow Modeling Language     │ │
│*│ │    Manual" (Version 4). 2020. Available online:    │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Knapsack problem." Wikipedia. Wikimedia           │ │
│*│ │    Foundation, August 26, 2021.                    │ │
│*│ │    https://en.wikipedia.org/wiki/Knapsack_problem  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ event attribute, number; optimization, weight;     │ │
│*│ | BUILD block; WITHIN command; report, global        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 4: 7 traces in less than 1 sec.              │ │
│*│ │ Scope 5: 7 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Knapsack

ATTRIBUTES { number limit, accumulated_total, current_max,
    				A_count, B_count, C_count;};

GLOBAL.limit := 11;

ROOT 	A: (* Item_A *)
	BUILD{ accumulated_total := #Item_A * 2;
   	};

accumulated_total +:= A.accumulated_total;
IF accumulated_total > GLOBAL.limit THEN REJECT; FI;

ROOT 	B: (* Item_B *)
	BUILD{ accumulated_total := #Item_B * 3;
   	};

accumulated_total +:= B.accumulated_total;
IF accumulated_total > GLOBAL.limit THEN REJECT; FI;

ROOT 	C: (* Item_C *)
	BUILD{ accumulated_total := #Item_C * 5;
   	};

accumulated_total +:= C.accumulated_total;
IF accumulated_total > GLOBAL.limit THEN REJECT; FI;

/* if got so far, check whether accumulated_total can be stored as result */
GRAPH candidates{};

IF accumulated_total >= GLOBAL.current_max THEN 
	GLOBAL.current_max := accumulated_total;

	/* add potential candidate to the list */
	WITHIN candidates{    
		Node$a: NEW(trace_id);
		Node$a.accumulated_total := accumulated_total;
        Node$a.A_count := #Item_A;
        Node$a.B_count := #Item_B;
        Node$a.C_count := #Item_C;
        SAY("Best result so far: " accumulated_total);
        };

 ELSE REJECT;
FI;

GLOBAL
REPORT best_knapsack{TITLE("Best knapsack");};

SAY("Weight limit " limit) => best_knapsack;
SAY("Single item's weight: A= 2 B= 3 C= 5" ) => best_knapsack;
SAY("For scope " $$scope " best packing is " current_max) => best_knapsack;

WITHIN candidates{
    FOR Node$x DO
    	IF Node$x.accumulated_total == current_max THEN
    		SAY("Pack "
                Node$x.A_count " of A, " 
                Node$x.B_count " of B, " 
    			Node$x.C_count " of C"		) => best_knapsack;
    	FI;
    OD;
    };

SHOW best_knapsack;
