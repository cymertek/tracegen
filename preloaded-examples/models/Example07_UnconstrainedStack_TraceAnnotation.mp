/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 07. Model of Unconstrained Stack           │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate a technique for debugging using     │ │
│*│ │ trace annotation.                                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Assertion checking with the CHECK clause may be    │ │
│*│ │ the simplest and most common tool for finding      │ │
│*│ │ counterexamples of traces, which violate some      │ │
│*│ │ property. Traces violating the CHECK condition are │ │
│*│ │ marked, and the message provides some hint about   │ │
│*│ │ the cause. The message is associated with the      │ │
│*│ │ root, composite, or the whole schema, and further  │ │
│*│ │ details may require browsing of the corresponding  │ │
│*│ │ trace segment. The following example demonstrates  │ │
│*│ │ how to make messages more specific and focused.    │ │
│*│ │                                                    │ │
│*│ │ Let’s consider again the Stack model, but this     │ │
│*│ │ time without the ENSURE constraint on the Stack    │ │
│*│ │ behavior. This Stack certainly will produce        │ │
│*│ │ unwanted behaviors. The MP code illustrates how to │ │
│*│ │ pinpoint events that might violate certain         │ │
│*│ │ property, and how to annotate these particular     │ │
│*│ │ events in the trace with additional messages.      │ │
│*│ │ Programmers will recognize the use of debugging    │ │
│*│ │ print statements for traditional program           │ │
│*│ │ testing/debugging.                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 11: Testing/Debugging model’s behavior"   │ │
│*│ │ from Auguston, M. "Monterey Phoenix System  and    │ │
│*│ │ Software Architecture and Workflow Modeling        │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stack; testing; debugging;               │ │
│*│ │ trace annotation; isomorphism                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 7 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 15 traces in less than 1.5 sec.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Unconstrained_Stack
ROOT Stack: (*  ( push | pop [ bang ])  *)
	/* bang event represents the Stack underflow event  */

	BUILD {
	/* 	By default the domain for event selection is FROM THIS. 
    
    	The following ENSURE makes sure that each attempt to pop empty Stack 
    	is followed by bang event */
        
		ENSURE FOREACH $p: pop
        /* pop associated with the bang event does not affect Stack contents,
        	hence only successful pop events do count   */

			(#pop BEFORE $p - #bang BEFORE $p) >= #push BEFORE $p
        		<-> #bang FOLLOWS $p == 1;

	COORDINATE $b: bang

		/* pick up pop event immediately preceding bang */
		DO COORDINATE $x: pop SUCH THAT $x PRECEDES $b
				DO  ADD SAY("This event tries to pop empty Stack")
  						PRECEDES $x;
					MARK;
				OD;
		OD; 
	};

/* Now traces where Stack behavior is incorrect will be MARKed and 
	corresponding pop events will be pointed to by PRECEDES arrow leading 
    from the message box associated with this event.  
*/
