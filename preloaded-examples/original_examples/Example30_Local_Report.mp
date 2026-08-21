
/* Example 30. Local Report within a trace.
	run for scope 1 and up.
*/
SCHEMA Data_flow

ROOT Writer: (* ( working | writing ) *);

ROOT File:   (+ writing +) (* reading *);
Writer, File SHARE ALL writing;
	
ROOT Reader: (* ( reading | working ) *);
Reader, File SHARE ALL reading;

REPORT basic_statistics {
		TITLE ("scope= " $$scope " trace " trace_id);};

/* Clear the contents after a trace derivation has been completed */
CLEAR basic_statistics;

/* fill the Report with data from the current event trace */
SAY("#writing= " #writing) => basic_statistics;
SAY("#reading= " #reading) => basic_statistics;
SAY("#working= " #working) => basic_statistics;


/* In order to make it visible together with the event trace, the SHOW command is needed */
SHOW basic_statistics;

