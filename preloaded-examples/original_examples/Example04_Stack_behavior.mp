/* Example4_Stack_behavior.mp 

The event trace is a set of events and the Boolean expression constructs in MP 
can support the traditional first order predicate calculus notation. 

A set of behaviors (event traces) may be defined by the event
grammar rules, composition operations, and some additional constraints – 
ENSURE conditions.

run for scopes 1, 2, 3, and up.
*/

/* This rule specifies the behavior of a stack in terms of stack operations 
push and pop. It is assumed that initially Stack is empty. 
The BUILD block associated with a root or composite event 
contains composition operations performed when event trace segment 
representing the behavior of that root or composite is generated. 

The ENSURE Boolean expression provides a condition that each valid trace 
should satisfy. The domain of the universal quantifier is the set of all 
pop events inside Stack trace. The FROM Stack part is optional, by default it is 
assumed to be FROM THIS.

The function #pop BEFORE $x yields the number of pop events preceding $x. 
The set of valid event traces specified by this schema contains only traces 
that satisfy the constraint. This example presents a filtering operation 
as yet another kind of behavior composition, and demonstrates an
example of combining imperative (event grammar) and declarative 
(Boolean expressions) constructs for behavior specification.
*/

SCHEMA Stack_behavior

ROOT Stack: (* ( push | pop ) *)
		BUILD { 
            /* if an element is retrieved, it should have been stored before */
            ENSURE FOREACH $x: pop FROM Stack
					( #pop BEFORE $x < #push BEFORE $x );

        /* The following composition operation establishes push/pop pairs
            in the Stack behavior. For each 'pop' the closest in time 
            preceding 'push' is selected, unless it has been already 
            consumed by another 'pop' */

            COORDINATE  $get: pop 
                DO COORDINATE <REVERSE> $put: push 
                                        SUCH THAT $put BEFORE $get 
                    DO 	IF 	NOT ( EXISTS $g: pop $put Paired_with $g OR
                                  EXISTS $p: push $p Paired_with $get 	)
                        THEN ADD $put Paired_with $get; FI;
                    OD;
                OD;
        };/* end BUILD for Stack */
