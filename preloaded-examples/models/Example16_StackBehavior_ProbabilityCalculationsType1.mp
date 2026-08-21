/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 16. Model of Stack Behavior                │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To obtain the probability of each valid trace.     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a behavior model of simple stack behavior. │ │
│*│ │ Valid behaviors don’t permit a scenario when the   │ │
│*│ │ Pop operation is applied to an empty stack, so we  │ │
│*│ │ apply the ENSURE constraint in the BUILD block.    │ │
│*│ │ For the purpose of this example, we assign a       │ │
│*│ │ higher probability to Push than to Pop. We also    │ │
│*│ │ assume that probabilities to perform 0, 1 or more  │ │
│*│ │ iterations by the iterative event pattern          │ │
│*│ │ (* ... *) are equal.                               │ │
│*│ │                                                    │ │
│*│ │ Consider a test of the following model of stack    │ │
│*│ │ behavior at scope 2. Because a pop cannot occur    │ │
│*│ │ before a push, the model rejects the scenarios     │ │
│*│ │ where a single pop alone occurs, a pop occurs      │ │
│*│ │ before a push, and 2 pops occur with no pushing.   │ │
│*│ │ These would all be impossible in a real stack, so  │ │
│*│ │ they are cut from the model.                       │ │
│*│ │                                                    │ │
│*│ │ The probability of each valid trace (p= ...) is    │ │
│*│ │ calculated in MP as follows. The product of        │ │
│*│ │ probabilities assigned to events in each           │ │
│*│ │ unconstrained trace segment is obtained. The       │ │
│*│ │ probabilities of traces cut from the model by      │ │
│*│ │ constraint(s) are discarded, and the probabilities │ │
│*│ │ of the remaining (valid) traces are normalized to  │ │
│*│ │ sum up to 1. The normalization is done by summing  │ │
│*│ │ the probabilities of only the valid traces and     │ │
│*│ │ then dividing each valid trace's probability by    │ │
│*│ │ that sum. This prorating operation distributes the │ │
│*│ │ contributions that would have been made by the     │ │
│*│ │ rejected traces equally across the valid traces.   │ │
│*│ │ This calculation is referred to in the MP Manual   │ │
│*│ │ as "Type 1 probability" and is appropriate for     │ │
│*│ │ models containing events whose probabilities are   │ │
│*│ │ not dependent on other events it is related to by  │ │
│*│ │ precedence or inclusion.                           │ │
│*│ │                                                    │ │
│*│ │ If << >> is not used to specify a probability,     │ │
│*│ │ equal probability across alternatives is assumed.  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 30: Type 1 probability" from Auguston, M. │ │
│*│ │ "Monterey Phoenix System and Software Architecture │ │
│*│ │ and Workflow Modeling Language Manual"             │ │
│*│ │ (Version 4). 2020. Available online:               │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, stack; probability, Type 1;              │ │
│*│ │ ENSURE condition                                   │ │
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

ROOT Stack: (* (<<0.75>> Push | <<0.25>> Pop ) *)

BUILD { /* If an element is retrieved, it should have been stored before */
		ENSURE FOREACH $x: Pop FROM Stack
			( #Pop BEFORE $x < #Push BEFORE $x ); };
