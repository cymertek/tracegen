/*  This decision logic first checks a condition, 
	then specifies an alternative for each potential 
	value of the condition. (MP Manual section 2.2)  */

SCHEMA Simple_Condition_Check

ROOT System:	Check_condition
				( Condition_1   Do_an_activity			|
				  Condition_2  	Do_a_different_activity	)
				;

/* See the Global View for the activity diagram for this logic. */

GLOBAL
SHOW ACTIVITY DIAGRAM System;
