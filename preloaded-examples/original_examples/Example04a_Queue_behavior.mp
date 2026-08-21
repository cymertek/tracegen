/* Example4a_Queue_behavior.mp 

run for scopes 1, 2, 3, and up.
*/

/* This rule specifies the behavior of a queue in terms of queue operations 
enqueue and dequeue. It is assumed that initially Queue is empty. 
The BUILD block associated with a root or composite event 
contains composition operations performed when event trace segment 
representing the behavior of that root or composite is generated. 

The ENSURE Boolean expression provides a condition that each valid trace 
should satisfy. The domain of the universal quantifier is the set of all 
dequeue events inside Queue trace. 

The function #dequeue BEFORE $x yields the number of dequeue events preceding $x. 
The set of valid event traces specified by this schema contains only traces 
that satisfy the constraint. This example presents a filtering operation 
as yet another kind of behavior composition, and demonstrates an
example of combining imperative (event grammar) and declarative 
(Boolean expressions) constructs for behavior specification.            */

SCHEMA Queue_behavior

ROOT Queue: (* ( enqueue | dequeue ) *)
	BUILD { 
        /* if an element is retrieved, it should have been stored before,
            this constraint is identical to Stack behavior constraint. */
        ENSURE FOREACH $x: dequeue 
				( #dequeue BEFORE $x < #enqueue BEFORE $x );

     /* The following composition operation establishes enqueue/dequeue pairs
     	in the Queue behavior. For each 'dequeue' the earliest in time 
     	preceding 'enqueue' is selected, unless it has been already 
        consumed by another 'dequeue' */
     
	COORDINATE  $get: dequeue 
		DO COORDINATE $put: enqueue 
                            SUCH THAT $put BEFORE $get 
			DO 	IF NOT ( EXISTS $g: dequeue $put Paired_with $g OR
						 EXISTS $p: enqueue $p Paired_with $get 	 )
				THEN ADD $put Paired_with $get; FI;
			OD;
		OD;
    };/* end BUILD for Queue */
