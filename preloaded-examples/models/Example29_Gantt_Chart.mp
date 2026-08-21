/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 29. Model of Gantt Chart                   │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to construct a Gantt Chart  	 │ │
│*│ │ using event timing attributes.                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model shows how to assign non-zero timing     │ │
│*│ │ attributes to events and visualize the whole-trace │ │
│*│ │ duration of concurrent and sequential events using │ │
│*│ │ a Gantt Chart. The Gantt Chart is constructed from │ │
│*│ │ a BAR CHART with the ROTATE option. The task is to │ │
│*│ │ show, for each event in the trace, the earliest    │ │
│*│ │ start time and the longest duration.               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 50: Gantt chart" from Auguston, M.        │ │
│*│ │ "Monterey Phoenix System and Software Architecture │ │
│*│ │ and Workflow Modeling Language Manual"             │ │
│*│ │ (Version 4). 2020. Available online:               │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ graph, Gantt chart; statistics, assembling; table; │ │
│*│ │ graph, bar chart                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Gantt_Chart
ROOT A: a1 a2;

ROOT B: b1 a2 b2;

A, B SHARE ALL a2;

COORDINATE 	$a1: a1, $a2: a2, $b1: b1, $b2: b2
	DO
		SET $a1.duration AT LEAST 3;
		SET $a2.duration AT LEAST 5;
		SET $b1.duration AT LEAST 1;
		SET $b2.duration AT LEAST 2;
	OD;

TABLE gantt_1{ 
	TABS 	string event_name, 
			number start_time, 
			number duration_time;
};

BAR CHART gantt_2 { TITLE("Example of Gantt Chart");
	FROM gantt_1;
	X_AXIS event_name;
	ROTATE; /* to place the X_AXIS vertical */
};

COORDINATE <SORT> $e: $$ATOM
	DO 	/* add this event to the Table */ 
		gantt_1 		<|
			event_name: 	SAY($e),
			start_time: 	$e.start.smallest,
			duration_time:  $e.duration.largest;
	OD;

SHOW gantt_2;
