/*	Example43
 Histogram example, run for scopes 1, 2, 3, and up
*/
SCHEMA Example
ROOT A: (<<0.2>> a1 | <<0.3>> a2 | (* a3 *));
ATTRIBUTES { number count; };

GLOBAL
/* this GRAPH is used as a container to collect data about valid trace probabilities */
GRAPH Data { };

WITHIN Data{
    /* numerical_loop_header(40) is used to perform required interval calculations. */ 
    FOR Num$t: [1.. #$$TRACE] STEP 1 
        DO FOR Num$n: [0 .. 1] STEP 0.1
              DO
                 Node$x: LAST("[" Num$n ".." Num$n + 0.1 ")");        
                 /*  p - pre-defined trace probability attribute */
                 IF  Num$n <= #$$TP(Num$t) AND 
                     #$$TP(Num$t) < Num$n + 0.1 THEN 
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

