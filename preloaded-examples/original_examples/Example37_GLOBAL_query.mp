/* Example 37 GLOBAL query	

Unreliable message flow.
Assuming that probability for a message to get lost is 0.2,
find probability of a trace with more than 75% successfully received messages.

Since we are interested only in traces with at least one 'send' event,
the (+ ... +) iteration is used.

This example is small enough to try scopes larger than 5. 
That can be done using explicit iteration limit (running for instance, 
for scope 1), like:

ROOT 	Sender: 	(+<1..7> send +);
ROOT 	Receiver: 	(+<1..7> (receive |<<0.2>> does_not_receive) +);

	Run for scopes 1 and up.
*/
SCHEMA unreliable_message_flow

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
	SAY("In "count " of traces at least 75% of sent messages have been received") => R;
    SAY("At the given scope probability for at least 75% messages to pass through is " summary_probability) => R;

    SHOW R;

