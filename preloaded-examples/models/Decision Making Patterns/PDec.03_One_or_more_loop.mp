/*  This decision logic describes the behavior of doing an 
	activity at least once before checking the value of a
	condition that decides whether it will be done again. 
	The activity is repeated more than once as long as the 
	condition to continue the activity is met. (MP Manual 
	section 2.2)  */

SCHEMA One_or_More_Loop

ROOT System:	Do_an_activity
				Check_condition
				
				(*	Condition_to_Continue_is_True
					Do_an_activity
				   	Check_condition
				 *)
				
				Condition_to_Continue_is_False
				;

/* See the Global View for the activity diagram for this logic. */

GLOBAL
SHOW ACTIVITY DIAGRAM System;
