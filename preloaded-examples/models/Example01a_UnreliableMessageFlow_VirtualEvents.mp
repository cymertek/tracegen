/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 01a. Model of Unreliable Message Flow      │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the use of 'virtual events' for      │ │
│*│ │ representing the absence or lack of activity, in   │ │
│*│ │ this case, the event "does_not_receive."           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model of sending and receiving events         │ │
│*│ │ incorporates a possibility that some messages get  │ │
│*│ │ lost in the transition. The virtual event          │ │
│*│ │ "does_not_receive" conveys the absence of the      │ │
│*│ │ "receive" event.                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 8: Unreliable Communication model" from   │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, unreliable message flow;                 │ │
│*│ │ behavior, unreliable communications channel;       │ │
│*│ │ coordination, event; virtual event                 │ │
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

SCHEMA Unreliable_Message_Flow
ROOT 	Sender: 	(* send *);
ROOT 	Receiver: 	(* (receive | does_not_receive) *);

COORDINATE 	$x: send 							FROM Sender, 
			$y: (receive | does_not_receive)	FROM Receiver 
	DO 	ADD $x PRECEDES $y; OD;
