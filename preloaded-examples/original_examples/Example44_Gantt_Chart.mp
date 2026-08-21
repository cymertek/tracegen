/*	Example44
 Gantt chart example
*/
SCHEMA S
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

COORDINATE $e: $$EVENT
	DO 	/* add this event to the Table */ 
		gantt_1 		<|
			event_name: 	SAY($e),
			start_time: 	$e.start.smallest,
			duration_time:  $e.duration.largest;
	OD;

SHOW gantt_2;
