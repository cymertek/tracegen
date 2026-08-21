/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 27. Model of Table and Bar Chart           │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to assemble statistics about a  │ │
│*│ │ current trace in a table and then render the table │ │
│*│ │ as a bar chart.                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This example model shows how to create and         │ │
│*│ │ populate a table with data collected from a graph  │ │
│*│ │ container, and then produce a bar chart from the   │ │
│*│ │ data in the table.                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 48: Assembling statistics about a current │ │
│*│ │ trace in a table and rendering it as a bar chart"  │ │
│*│ │ from Auguston, M. "Monterey Phoenix System and     │ │
│*│ │ Software Architecture and Workflow Modeling        │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ table; graph, bar chart; statistics, assembling;   │ │
│*│ │ event attribute, number                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Table_and_Bar_Chart
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




