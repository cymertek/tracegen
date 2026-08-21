/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Railroad Crossing Safety                  │ │
│*│ │  Created by Mikhail Auguston in 2018.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate timing attribute use in MP, here for │ │
│*│ │ displaying a railroad crossing scenario.           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using BUILD statements to  │ │
│*│ │ add time to a model of car and train interactions  │ │
│*│ │ at a railroad crossing, in which time is a         │ │
│*│ │ defining factor of many events. Users should look  │ │
│*│ │ to this model when in need of an example of using  │ │
│*│ │ BUILD statements to add time, COORDINATE           │ │
│*│ │ constraint usage, CHECK statements used to catch   │ │
│*│ │ unwanted behavior, and SAY statement comments to   │ │
│*│ │ improve a model's clarity.                         │ │
│*│ │                                                    │ │
│*│ │ The original railroad crossing example was         │ │
│*│ │ provided by Heitmeyer and Mandrioli (1996). The    │ │
│*│ │ system operates a gate at a railroad crossing. A   │ │
│*│ │ sensor determines when each train enters and exits │ │
│*│ │ the crossing’s region. The main safety requirement │ │
│*│ │ is: if a train is in the crossing region, then     │ │
│*│ │ gate must be down.                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 24: Railroad crossing example" from       │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Heitmeyer, Constance, and Dino Mandrioli. Formal   │ │
│*│ │    Methods for Real-Time Computing. New York, NY:  │ │
│*│ │    John Wiley & Sons, Inc., 1996.                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, railroad crossing; safety requirement;   │ │
│*│ │ failure mode; event attribute, timing              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ │ Scope 2: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 3 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
