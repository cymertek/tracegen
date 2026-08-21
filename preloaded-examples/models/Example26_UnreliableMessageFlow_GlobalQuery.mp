/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 26. Model of Unreliable Message Flow with  │ │
│*│ │ Global Query                                       │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of GLOBAL attributes.       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This example uses the Unreliable Message Flow from │ │
│*│ │ Example 8 in the MP manual to show how to          │ │
│*│ │ answer/solve the following problem: Assuming the   │ │
│*│ │ probability for a message to get lost in           │ │
│*│ │ transition is 0.2, find the probability of a trace │ │
│*│ │ with more than 75% successfully received messages. │ │
│*│ │ Trace probabilities are calculated as Type 1 (see  │ │
│*│ │ MP manual section 2.20.1), and we will use a       │ │
│*│ │ global query to summarize the results across all   │ │
│*│ │ traces.                                            │ │
│*│ │                                                    │ │
│*│ │ Since we are interested only in traces with at     │ │
│*│ │ least one 'send' event, the (+ ... +) iteration is │ │
│*│ │ used.                                              │ │
│*│ │                                                    │ │
│*│ │ This example is small enough to try scopes larger  │ │
│*│ │ than 5. That can be done using explicit iteration  │ │
│*│ │ limit (running for instance, for scope 1), like:   │ │
│*│ │                                                    │ │
│*│ │ ROOT   Sender:     (+<1..7> send +);               │ │
│*│ │ ROOT   Receiver:   (+<1..7> (receive |<<0.2>>      │ │
│*│ │                     does_not_receive) +);          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 46: Global query Model of unreliable      │ │
│*│ │    message flow (related to Example 8)" from       │ │
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
│*│ │ behavior, unreliable message flow; query, global;  │ │
│*│ │ event attribute, number; query, probability        │ │
│*│ │ summary                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 14 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Unreliable_Message_Flow

ROOT 	Sender: 	(+ send +);
ROOT 	Receiver: 	(+ (receive |<<0.2>> does_not_receive) +);

COORDINATE 	$x: send 							FROM Sender, 
			$y: (receive | does_not_receive)	FROM Receiver 
	DO 	ADD $x PRECEDES $y; OD;

ATTRIBUTES {number 	trace_unique_id, 
					summary_probability,
    				count; };

GRAPH good_traces{ }; /* To accumulate data about traces of interest */

IF #receive / #send > 0.75 THEN 
	WITHIN good_traces {
		Node$x: NEW(trace_id);
		Node$x.trace_unique_id := trace_id; };
    MARK; /* MARK this trace */
FI;

GLOBAL
REPORT R{TITLE("Scope " $$scope);};

WITHIN good_traces{
	FOR Node$a 	DO
    /* sum up probabilities of traces stored in the 'good_traces'.
    	Please notice that trace's probability can be estimated only 
        after all valid trace derivation has been completed, 
        i.e. should be postponed to the GLOBAL section, 
        using the #$$TP( ) function. */
		summary_probability +:= #$$TP(Node$a.trace_unique_id);
    	count +:=1;
    OD;
    };

	SAY( "Total " #$$TRACE " traces") => R;
	SAY("In "count " of " #$$TRACE " traces at scope "$$scope", at least 75% of sent messages have been received") => R;
    SAY("At the given scope probability for at least 75% messages to pass through is " summary_probability) => R;

    SHOW R;

