/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 15. Model of Backpack Weight               │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of event interval           │ │
│*│ │ attributes for calculating a total weight range    │ │
│*│ │ for each event trace based on weights of           │ │
│*│ │ individual items in each trace, and to ensure a    │ │
│*│ │ total weight limit is not exceeded by any trace.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The task is to load a backpack with items not      │ │
│*│ │ exceeding a total weight of 30 units. There may be │ │
│*│ │ several instances of the same item.                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 22: Use of interval attributes" from      │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ event attribute, interval; optimization, weight;   │ │
│*│ │ BUILD block; SAY statement                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 5 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 9 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Backpack_Weight

ATTRIBUTES{ interval weight; };

/* Composite event is used to define attribute value for 
    all instances of a particular event */
item1:   BUILD{ weight := [2..5];};
item2:   BUILD{ weight := [10..16];};

ROOT Backpack: (+ (item1 | item2)  +)
BUILD{ 
    COORDINATE $item: (item1 | item2) 
        DO  SAY("selected " $item " with weight " $item.weight);
            /* interval weight is initialized by [0..0] */
            weight +:= $item.weight; 
        OD; 
    /* ensure that the backpack's weight does not exceed maximum */
    ENSURE weight > 0 AND weight <= 30; };

SAY("selected " #(item1 | item2) " items");
SAY("backpack weight is within interval " Backpack.weight);
