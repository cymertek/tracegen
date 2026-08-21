/*  This decision logic describes the behavior of checking 
	the value of a condition and then doing and possibly 
	repeating an activity as long as the condition value holds.
	The activity may not be performed at all if the condition
	to continue to the activity is not met. (MP Manual 
	section 2.2)  */

SCHEMA Zero_or_More_Loop

ROOT System:	Check_condition
				(* 	Condition_to_Continue_is_True
					Do_an_activity
				   	Check_condition 
                 *)
				
				Condition_to_Continue_is_False
;

/* See the Global View for the activity diagram for this logic. */

GLOBAL
SHOW ACTIVITY DIAGRAM System;
