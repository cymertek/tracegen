/***************************************
 Cycle_ISP Model for Systems Journal Article
 Available at https://www.mdpi.com/2079-8954/6/2/18
 created 2018-03-10 by K.Giammarco 

The model below describes a cycle in terms of a 
series of one or more steps, each step either 
moving the system "forward" or "backward" as the 
process unfolds.  "Forward" and "backward" are 
generic terms that may be substituted with synonyms 
such as "up" and "down," "in" and "out", "over" 
and "under", "increase" and "decrease", etc., or 
discinyms (discipline-specific synonyms) as they 
may appear in the preferred domain taxonomy.

Run the model for scopes 2, and 3 and inspect 
the different possible patterns for Cycle.  
Running at scope 1 will generate zero traces because
of the ENSURE constraint on line 29.

****************************************/

SCHEMA Cycle_ISP_v2

ROOT Cycle:   	(+ Initial_condition 
			  		(+ ( Step_forward | Step_backward ) +)
				   End_condition +);

ENSURE #( Step_forward | Step_backward ) > 1;


                   
/*Check for Positive Reinforcement Template */
IF EXISTS DISJ $a:  Step_forward, $b: Step_forward  
			$a PRECEDES $b THEN 
				SAY("Positive Reinforcement Detected"); FI;

/*Check for Negative Reinforcement Template */
IF EXISTS DISJ $a:  Step_backward, $b: Step_backward  
			$a PRECEDES $b THEN 
				SAY("Negative Reinforcement Detected"); FI;

/*Check for Oscillation Template */
IF EXISTS  $a:  Step_forward, $b: Step_backward  
			$a PRECEDES $b  OR
			$b PRECEDES $a 	THEN 
				SAY("Oscillation Detected"); FI;

/*Note Lifecycle Completion */
COORDINATE $a: End_condition
	DO ADD SAY("Lifecycle Complete") PRECEDES $a; OD;

/*Check for Recycle Template */
IF #Initial_condition > 1 THEN 
				SAY("Recycle Detected"); FI;


