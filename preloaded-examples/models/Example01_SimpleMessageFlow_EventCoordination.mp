/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 01. Model of Simple Message Flow           │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate how to set up separate event grammar │ │
│*│ │ rules and how to coordinate events from each of    │ │
│*│ │ those rules.                                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Event grammar rules for each root define the       │ │
│*│ │ derivations for event traces. In this case, we     │ │
│*│ │ have a simple sequence of zero or more events for  │ │
│*│ │ each root. The COORDINATE composition takes two    │ │
│*│ │ root traces and produces a modified event trace,   │ │
│*│ │ merging behaviors of Sender and Receiver and       │ │
│*│ │ adding the PRECEDES relation for the selected      │ │
│*│ │ send/receive pairs. The coordination operation     │ │
│*│ │ behaves as a "cross-cutting" derivation rule.      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 1: Simple interaction pattern" from       │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, simple message flow;                     │ │
│*│ │ simple interaction pattern; coordination, event    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up. Traces are generated in a │ │
│*│ │ sequence diagram-like format by default. Try       │ │
│*│ │ rotating a selected trace 90 degrees               │ │
│*│ │ counterclockwise, or (from the Options menu above  │ │
│*│ │ the diagram) selecting the "Swim Lanes" checkbox   │ │
│*│ │ to view the trace in an activity diagram format.   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 4 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Simple_Message_Flow

ROOT Sender:   (* send *);
ROOT Receiver: (* receive *);

COORDINATE	$x: send 	FROM Sender, 
			$y: receive FROM Receiver
	DO ADD $x PRECEDES $y; OD;
