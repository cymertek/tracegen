/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 28. Model of Histogram                     │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonsrate how to construct a probability       │ │
│*│ │ histogram from Type 1 probabilities of traces in   │ │
│*│ │ an MP model.                                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ A histogram represents the distribution of         │ │
│*│ │ numerical data into "bins" or "buckets." The first │ │
│*│ │ step is to define bins each representing a range   │ │
│*│ │ of values, and then to count the number of values  │ │
│*│ │ that fall into each interval. Type 1 probabilities │ │
│*│ │ are used as the values in this example.            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 49: Histogram showing number of traces    │ │
│*│ │ with probabilities within certain intervals" from  │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ graph, histogram; statistics, assembling;          │ │
│*│ │ event attribute, number; report, global;           │ │
│*│ │ probability, interval                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 5 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 6 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Histogram
ROOT A: (<<0.2>> a1 | <<0.3>> a2 | (* a3 *));
ATTRIBUTES { number count; };

GLOBAL
/* This GRAPH is used as a container to collect data about valid trace probabilities.
    The following MP code can be reused for any MP model just by Copy/Paste.    */
GRAPH Data { };

WITHIN Data{
    /* numerical_loop_header(40) is used to perform required interval calculations. */ 
    FOR Num$t: [1.. #$$TRACE] STEP 1 
        DO FOR Num$n: [0 .. 1] STEP 0.1
              DO
                    Node$x: LAST("[" Num$n ".." Num$n + 0.1 ")");        
                 /*  p - pre-defined trace probability attribute */
                    IF  ( Num$n <= #$$TP(Num$t) AND 
                          #$$TP(Num$t) < Num$n + 0.1) OR
        /* special case when the only single trace with probability 1 exists */ 
                        ( #$$TRACE == 1 AND Num$n == 0.9 ) THEN 
                     Node$x.count +:= 1;
                    FI; 
              OD;
        OD;  
}; /* end of WITHIN Data */

TABLE probability_histogram {
TABS string     probability_interval,
        number     trace_count; };

BAR CHART probability_chart { TITLE("Trace probabilities");
                              FROM     probability_histogram;
                              X_AXIS probability_interval; };
WITHIN Data{
    FOR Node$n
        DO probability_histogram     <| 
                 probability_interval:     SAY(Node$n),
                 trace_count:              Node$n.count;                                                     
        OD;
};

SHOW probability_chart SORT;
/* The contents of the chart is sorted by X_AXIS string values, since the order of adding rows to the
    TABLE may be arbitrary */

