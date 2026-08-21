/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 21. Model of Data Flow with Local Report   │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show how to produce a local report within a     │ │
│*│ │ trace.                                             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ A report is a sequence of related SAY clauses      │ │
│*│ │ assembled together to make it easier to read and   │ │
│*│ │ print. For example, some statistics can be put in  │ │
│*│ │ a single report, e.g., size of event trace, number │ │
│*│ │ of events, total duration. This model adds a basic │ │
│*│ │ local report to the Data Flow schema first         │ │
│*│ │ introduced in Example 3 from the MP manual. The    │ │
│*│ │ report has a title with the scope and trace        │ │
│*│ │ number, and its contents are filled with the       │ │
│*│ │ number of times each of the events "writing,"      │ │
│*│ │ "reading," and "working" appear in the trace.      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 39: Local Report within a single trace"   │ │
│*│ │    from Auguston, M. "Monterey Phoenix System and  │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Example 3: Data Flow model from the Monterey      │ │
│*│ │    Phoenix" from Auguston, M. "Monterey Phoenix    │ │
│*│ │    System and Software Architecture and Workflow   │ │
│*│ │    Modeling Language Manual" (Version 4). 2020.    │ │
│*│ │    Available online:                               │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, data flow; report, local;                │ │
│*│ │ statistics, basic                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 28 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 165 traces in less than 1 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Data_Flow_with_Local_Report

ROOT Writer: (* ( working | writing ) *);

ROOT File:   (+ writing +) (* reading *);
Writer, File SHARE ALL writing;
	
ROOT Reader: (* ( reading | working ) *);
Reader, File SHARE ALL reading;

REPORT basic_statistics {
		TITLE ("scope= " $$scope " trace " trace_id);};

/* Clear the contents after a trace derivation has been completed; 
   this prevents accumulation of data from previous traces  */
CLEAR basic_statistics;

/* fill the Report with data from the current event trace */
SAY("#writing= " #writing) => basic_statistics;
SAY("#reading= " #reading) => basic_statistics;
SAY("#working= " #working) => basic_statistics;


/* In order to make it visible together with the event trace, the 
   SHOW command is needed */
SHOW basic_statistics;

