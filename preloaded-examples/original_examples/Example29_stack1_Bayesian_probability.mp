/* Example 29

	An example of  Bayesian probability calculation.

	run for scopes 1, 2, 3, and up.
    
    This example illustrates the main parts in probabilistic MP model construction:
    
    1) selection of the search space - the finite number of event instances, 
    	including the event trace, which is an event by itself.
    2) Rules for event attribute p2 calculation.
    3) The p2 attribute represents the probability for a particular event 
    	instance (including the trace) to appear on the MP output.
        
    When run on Firebird, the output also shows Type 1 trace probability 
    (p=nnnn on the right scroll bar), 
    which will be different from the calculated Type 2 values.
    
    Note. For this simple example it is possible to run more than 5 iterations 
    of push/pop (beyond the max standard scope of 5) by using the explicit iteration option,
    where M is the desired number of iterations.
    
    ROOT Stack: (*<0..M> ( <<0.75>> push | <<0.25>> pop ) *)
    this will require to update the first step in p2 assignment (line 57)
    it will become p2 := 1/(M + 1);
==================================================================*/

SCHEMA stack1

ROOT Stack: (* ( <<0.75>> push | <<0.25>> pop ) *)
		/* probabilities for alternatives are here to enable also 
			the default Type 1 trace probability calculation, in order 
			to compare it with the Bayesian */
	BUILD { 
        /* if an element is retrieved, it should have been stored before */
          ENSURE FOREACH $x: pop FROM Stack
			( #pop BEFORE $x < #push BEFORE $x );
    }
;/* end BUILD for Stack */

/*==============================================================*/
/* here starts the part of model responsible for Bayesian logic */
/*==============================================================*/
ATTRIBUTES{ number p2;};
/* the attribute p2 represents a probability of event 
	to be included in the current trace.
    Since the whole trace also is an event, 
    attribute p2 for it specifies the trace probability - 
    the target of all this example */

/* first, let's bring the probability to select the number of iterations.
	For scope $$scope there may be 0, 1, 2, ... $$scope iterations.
	Total ($$scope + 1) choices.
	Hence: assuming that each choice has equal probability 1/($$scope + 1)
    stand alone p2 is attribute of the whole event trace */

	p2:= 1/($$scope + 1);
/* 	here the default is THIS.p2 := 1/($$scope + 1); 
	p2 is an attribute of the whole trace.
    The interpretation: "the probability of getting the trace segment so far" */

/* by now the valid trace has been derived 
	and we can proceed with decorating its events with attribute values.
    COORDINATE traverses its thread in order of derivation (the default) */
COORDINATE $e: (pop | push)
DO
	IF #pop BEFORE $e ==  #push BEFORE $e THEN 
		/* if the condition above holds, the choice of event $e 
        is unambiguous: it should be 'push', 
        and its probability is the same as for the previous event */
	ELSE
		/* otherwise we have to choose one of the pop/push 
        	with corresponding probability.
			Notice that the option #pop BEFORE $e > #push BEFORE $e has been eliminated 
			by ENSURE filter during the valid trace derivation */
		IF $e IS pop THEN p2 *:= 0.25;
					 ELSE p2 *:= 0.75; /* for 'push' */
		FI;
	FI;

	/* Now we can set the probability for $e,
    	this is done for the purpose to show the sequence of pop/push later.
       This $e.p2 attribute is not actually needed in order 
        to calculate p2 for the trace */ 
	$e.p2 := p2;
OD;

/*=================================================*/
/* for debugging purposes let's show the sequence 
	of pop/push with their probabilities in order of derivation */
COORDINATE $x: (pop | push)
	DO SAY($x " with probability " $x.p2); OD;

/**** final report ****/
SAY("Trace " trace_id " for scope " $$scope " has probability " p2);
