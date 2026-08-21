/* Example 26, timing attribute use

	also demonstrates how to print all 
	events present in the trace 
	with timing attributes

    run for scopes 1 and up
*/
SCHEMA Delays

Work:
BUILD{
    SET duration AT LEAST 1;
    /* The new default value for the Work event duration 
		attribute is set as an interval [1..1] */
};


Visitor:
	/* set new default duration for Visitor */
BUILD{ SET duration AT LEAST [2..3]; };

Get_distracted:    (+ Visitor +) ;

ROOT Worker: (+ ( Work | Get_distracted) +);

ATTRIBUTES{ interval total_delay; };
/* delay is THIS.delay, or attribute of the whole schema event,
  and  is used to hold specific data extracted from the trace */

COORDINATE $distraction: Get_distracted
    DO total_delay +:= $distraction.duration; OD;

/* show all events present in the trace with timing attributes, 
  preserving the order of derivation, top-down, left-to-right */
COORDINATE $x: $$EVENT 
	DO SAY("   " $x 	" start " $x.start 
						" duration " $x.duration 
						" end " $x.end); 
	OD;

SAY("  Delay created by " #Visitor " visitors is " total_delay);
