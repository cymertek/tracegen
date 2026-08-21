/*
 Example42
 Assembling statistics about a current trace in a TABLE and rendering it.
 Table and bar chart example, run for scope 1
*/

SCHEMA Example
ROOT A: a b c a;

TABLE trace_stats {
	TITLE ("Trace " trace_id);
TABS 	string event_name, 
number total_number;
};

BAR CHART chart_states {
	TITLE( "Trace " trace_id " chart"); 
	FROM trace_stats; 
/* contents of the  bar chart is derived from 
	the table trace_stats */
	X_AXIS event_name;
};

GRAPH event_counters { };
/* This graph container is used as an associative array 
	data structure to accumulate event count 
    for each event in the trace via node attributes */ 
ATTRIBUTES {number count;};

/* Collect event data and store it in the graph container */
WITHIN event_counters{
	COORDINATE $e: $$EVENT 	/* loop over all events within the trace */
		DO 	Node$a: LAST ($e); 
			Node$a.count +:=1; /* increment node’s attribute value */
  		OD;
	/* Second loop - now fill the table, see loop_over_graph (105) */ 
	FOR Node$n /* variable Node$n is traversing event_counters node set */
		DO	
			trace_stats <| /* store tuple in the table trace_stats */
				event_name :	SAY(Node$n), 
					/* here (Node$n) is a string_constructor(87) 
						converting node’s name (label) into a character string   */ 
				total_number: 	 Node$n.count 		; 		 			
		OD;
}; /* end WITHIN */

SHOW trace_stats;
SHOW chart_states;
/* contents of the related table provides data source for the bar chart */




