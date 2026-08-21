/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 19. Model of Stack Behavior with           │ │
│*│ │ Conditional Probability                            │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To obtain the probability of an event instance     │ │
│*│ │ (including the event trace itself), and to show    │ │
│*│ │ how to make the probability of an event dependent  │ │
│*│ │ on events happening before it.                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model uses the stack behavior model to        │ │
│*│ │ illustrate the main parts in probabilistic MP      │ │
│*│ │ model construction:                                │ │
│*│ │    1) define the search space,                     │ │
│*│ │    2) define the probability calculation rules,    │ │
│*│ │    3) calculate the probability for a particular   │ │
│*│ │       event instance (including the trace) to      │ │
│*│ │       appear on the MP output.                     │ │
│*│ │ The question is, "What is the probability of each  │ │
│*│ │ trace at each scope 1-3, given that the stack is   │ │
│*│ │ constrained to pop only if push occurs before it?" │ │
│*│ │                                                    │ │
│*│ │ When run on Firebird, the output also shows Type 1 │ │
│*│ │ trace probability (p=nnnn on the right scroll bar),│ │
│*│ │ which will be different from the calculated Type 2 │ │
│*│ │ values. This difference is owed to the fact that   │ │
│*│ │ Type 1 assumes that probability of selecting an    │ │
│*│ │ alternative is constant for the whole derivation   │ │
│*│ │ process, whereas Type 2 provides for the           │ │
│*│ │ construction of probability calculation rules that │ │
│*│ │ account for dependencies on previous events that   │ │
│*│ │ have happened in the trace.                        │ │
│*│ │                                                    │ │
│*│ │ Note. For this simple example it is possible to    │ │
│*│ │ run more than 5 iterations of push/pop (beyond the │ │
│*│ │ max standard scope of 5) by using the explicit     │ │
│*│ │ iteration option. If this is desired then update   │ │
│*│ │ the following lines for M, where M is the desired  │ │
│*│ │ number of iterations.                              │ │
│*│ │                                                    │ │
│*│ │ (line 56)  ROOT Stack: (*<0..M> ( <<0.75>> push |  │ │
│*│ │                        <<0.25>> pop ) *)           │ │
│*│ │ (line 100) p2 := 1/(M + 1);                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 33: Bayesian probability calculation"     │ │
│*│ │ from Auguston, M. "Monterey Phoenix System and     │ │
│*│ │ Software Architecture and Workflow Modeling        │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stack; event attribute, number;          │ │
│*│ │ probability, Type 2; probability, Bayesian         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 7 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Stack_Behavior

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

/* 1) 	Define the search space.  The search space for this example 
		includes the finite number of event instances including 
		events in each trace and traces in the schema.  

   2) 	Define the probability calculation rules.  The event 
		attribute p2 represents the probability for a particular 
		event instance (including the trace) to appear on the MP 
		output.

   3) 	Calculate the probability for a particular event instance 
   		(including the trace) to appear on the MP output  */

ATTRIBUTES{ number p2;};
/* the attribute p2 represents a probability of event to be included 
   in the current trace.  Since the whole trace also is an event, 
   attribute p2 for it specifies the trace probability - the target 
   of all this example */

/* first, let's bring the probability to select the number of 
   iterations.  For scope 1 the number of iterations is 2 (0 and 1).
   For scope 2 the number of iterations is 3 (0, 1, and 2).  For 
   scope $$scope there may be 0, 1, 2, ... $$scope iterations. The
   pattern: total ($$scope + 1) choices for the run scope. Assuming 
   that each choice has equal probability, the probability of each
   choice is 1/($$scope + 1).  This formula scales the subsequent 
   trace probability calculations to the probability of the iteration 
   within the schema so that p2 sums to 1 for all traces in the 
   schema. */

	p2:= 1/($$scope + 1);
/* 	here the default is THIS.p2 := 1/($$scope + 1); 
	p2 is an attribute of the whole trace.
    The interpretation: "the probability of getting the trace segment 
	so far."  p2 accumulates event probabilities in the trace to 
	arrive at the whole trace probability. */

/* At this point the valid trace has been derived and we can proceed 
   with decorating its events with attribute values.  COORDINATE 
   traverses its thread in order of derivation (the default). */

/* For each event $e in the trace that is a push or a pop */
COORDINATE $e: (pop | push)
DO
	/* If there are an equal number of pop and push events before $e
	   then maintain the same p2 as for the previous event */ 

	IF #pop BEFORE $e ==  #push BEFORE $e THEN 

	/* if the condition above holds, the choice of event $e is 
	   unambiguous: it should be 'push' because the option 
	   #pop BEFORE $e > #push BEFORE $e has been eliminated by ENSURE 
	   filter during the valid trace derivation.  This condition keeps 
	   p2 the same as it was for the previous event. */

	ELSE
		/* otherwise we apply the probability corresponding to the
		   push or pop event. */

		IF $e IS pop THEN p2 *:= 0.25;
					 ELSE p2 *:= 0.75; /* for 'push' */
		FI;
	FI;

	/* For trace annotation purposes, we can set the probability for 
	$e as $e.p2 to store the p2 value for that event. This $e.p2 
	attribute is not actually needed in order to calculate p2 for the 
	trace, but is stored for the purpose to show the sequence of 
	pop/push later in the traces. */ 
	$e.p2 := p2;
OD;

/*=================================================*/
/* for debugging purposes let's show the sequence 
   of pop/push with their probabilities in order of derivation */
COORDINATE $x: (pop | push)
	DO SAY($x " with probability " $x.p2); OD;

/**** final report ****/
SAY("Trace " trace_id " for scope " $$scope " has probability " p2);
