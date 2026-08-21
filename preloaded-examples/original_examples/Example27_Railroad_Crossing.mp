/*
Example 27.	Timing attribute use.

Railroad crossing example from [Formal Methods for Real-Time Computing, 1996].
The system operates a gate at a railroad crossing. A sensor determines when 
each train enters and exits the crossing’s region. 

The main safety requirement is: if a train is in the crossing region, 
then gate must be down.

*/

SCHEMA Railroad_Crossing

ROOT Train: 
	(+
		Enter_Restricted_Region
		Goes_through_Restricted_Region
		Enter_Crossing_Region
		Goes_through_Crossing_Region
		Leaves_Crossing_Region
	+) ;

ROOT Crossing:
	(+
		Move_Down
		Down
		Move_Up
		Up
	+) ;

/* Set values for duration attributes */
/*================================================*/
Goes_through_Crossing_Region: BUILD{ SET duration AT LEAST 10; };

Move_Down: BUILD{ SET duration AT LEAST 5; };

Move_Up: BUILD{ SET duration AT LEAST 2; }; 

COORDINATE 	$enter: Enter_Restricted_Region 	FROM Train,
			$down: 	Move_Down 					FROM Crossing
	DO ADD $enter PRECEDES $down; OD;

COORDINATE 	$enter: Enter_Crossing_Region 		FROM Train,
			$down:  Down 						FROM Crossing
	DO ADD $down PRECEDES $enter; OD;

COORDINATE 	$leaves: 	Leaves_Crossing_Region 	FROM Train,
			$up: 	 	Move_Up 				FROM Crossing
	DO ADD $leaves PRECEDES $up; OD;

/* The main safety condition */
CHECK FOREACH $enter: Goes_through_Crossing_Region FROM Train 
				NOT EXISTS $up: Up FROM Crossing
									MAY_OVERLAP $enter $up
	ONFAIL SAY("Crossing is open when train is passing through!");

COORDINATE 
    $goes_through: Goes_through_Crossing_Region FROM Train,
    $down: Down                                 FROM Crossing,
    $bar_is_up: Move_Up                         FROM Crossing
DO 
    SAY("Bar moved down by " $down.end );
    SAY("Train starts go through crossing at " $goes_through.start);
    SAY("Train ends go through crossing at " $goes_through.end);
    SAY("Bar starts go up at " $bar_is_up.start);
    IF $goes_through.start < $down.end THEN
                SAY("Not enough time to close crossing");
    ELSE        SAY("Crossing was successfully closed"); 
    FI;
OD;
