/* Example 31. Global report.
	run for scope 1 and up
-----------------------------*/
SCHEMA simple_message_flow

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
