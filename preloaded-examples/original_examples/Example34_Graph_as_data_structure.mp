/* Example 34.
 	Accumulating and rendering statistics from event traces.
 	Graphs as container data structures
============================================================*/
SCHEMA Statistics
ROOT A: (* ( a | b) *);
ROOT B: (+ c +);

GRAPH Stat{ TITLE("Total event count as graph for scope " $$scope);};

ATTRIBUTES { number count;};

COORDINATE $x: $$EVENT DO
	WITHIN Stat{
		Node$e: LAST ($x); /* creates new node with label $x if needed, 
								or finds the existing one  */
		Node$e.count +:= 1;
		/* add more data to the node */
		ADD Node$e  ARROW("in trace")  LAST("trace " trace_id);
	};
OD;

GLOBAL 
/* Render the accumulated statistics as Report.
	The Stat graph is used as a data structure. */
REPORT Total_event_statistics{ TITLE("Total event count as Report"); };

	WITHIN Stat{
		FOR Node$a DO
			IF Node$a.count > 0 THEN
			/* 	Nodes with “trace” labels have count attribute 0.
			 Create and connect new node with the total count to each event node */
				ADD Node$a ARROW("total count") NEW (Node$a.count);
			/* graph loop works only with the initial graph contents, 
				new nodes added within the loop body
 				don’t participate in the iterations. 
                That prevents from infinite looping. */

			/* Add to the Report as well. 
            	Use the graph as a source of accumulated data.  */
				SAY(Node$a " event count: " Node$a.count) 
 						=> Total_event_statistics;
			FI;
	OD; /* end FOR */
	}; /* end WITHIN */

	/* render statistics as a graph */
	SHOW Stat;
	/* show the Report */
	SHOW Total_event_statistics;
