/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 22. Model of Unreliable Message Flow with  │ │
│*│ │ Global Report                                      │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show how to produce a global report across all  │ │
│*│ │ traces.                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ A global report may be used to assemble            │ │
│*│ │ information about all traces, e.g., total number   │ │
│*│ │ of traces, total number of events, average /       │ │
│*│ │ minimum / maximum values of event attributes, etc. │ │
│*│ │ This model adds a basic - global report to the     │ │
│*│ │ Unreliable Message Flow schema first introduced in │ │
│*│ │ Example 8 from the MP manual. The report has a     │ │
│*│ │ title with the scope, and its contents are filled  │ │
│*│ │ with the number of sent events, number of receive  │ │
│*│ │ events, and the ratio of receive/send for each     │ │
│*│ │ trace that did not have perfect reception.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 40: Global report assembled from the set  │ │
│*│ │    of all available event traces" from             │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Example 8: Unreliable Communication model" from   │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, unreliable message flow; report, global; │ │
│*│ │ statistics, global                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 7 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 15 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Unreliable_Message_Flow_with_Global_Report

ROOT Sender:   (* send *);

ROOT Receiver: (* (receive | does_not_receive) *);

COORDINATE	$x: send 						 FROM Sender, 
			$y: (receive | does_not_receive) FROM Receiver
		DO ADD $x PRECEDES $y; OD;

REPORT statistics { TITLE ("scope= " $$scope);};

/* for each valid trace add report records */
IF #does_not_receive > 0 THEN
		SAY( 	"trace " trace_id " sent " #send
		  		" received " #receive
				" ratio " #receive/#send ) 	=> statistics;
FI;
/* Since no CLEAR operation is present, the contents of Report is preserved 
	and augmented for each valid event trace */

GLOBAL 

SAY( "total traces " #$$TRACE) => statistics; 
/* Global expression #$$TRACE provides number of valid event traces derived 
	for the current scope */ 

SHOW statistics;
