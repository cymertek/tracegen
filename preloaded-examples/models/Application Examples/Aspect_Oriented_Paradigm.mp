/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Aspect Oriented Paradigm                  │ │
│*│ │  Created by Mikhail Auguston in 2018.              │ │
│*│ │  Edited by Pamela Dyer in September, 2021.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the Aspect-Oriented Programming     │ │
│*│ │ paradigm in MP.                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Aspect-Oriented Programming (AOP) [Kiczales et al. │ │
│*│ │ 1997] is a programming approach that separates the │ │
│*│ │ logic into distinct "concerns," each of which      │ │
│*│ │ pertains to a cohesive area of functionality.      │ │
│*│ │ Some concerns are "cross-cutting," that is, they   │ │
│*│ │ necessarily involve multiple parts of a program.   │ │
│*│ │ The behavior of the base code can be modified by   │ │
│*│ │ the aspect by applying "advice" (additional        │ │
│*│ │ behavior) at "join points" (specific points in a   │ │
│*│ │ program).                                          │ │
│*│ │                                                    │ │
│*│ │ The COORDINATE operation in MP supports a          │ │
│*│ │ "cause-effect" refinement for the behavior of two  │ │
│*│ │ components and it bears a certain similarity to    │ │
│*│ │ the AOP paradigm. For example, an AOP pattern      │ │
│*│ │ could be modeled in an MP schema where event       │ │
│*│ │ coordination implements AOP join point and advice  │ │
│*│ │ coordination.                                      │ │
│*│ │                                                    │ │
│*│ │ Suppose that the main stream of execution (Main)   │ │
│*│ │ contains calls to methods M1 and M2 as join        │ │
│*│ │ points, and the aspect behavior requires a call to │ │
│*│ │ Prolog before, and to Epilog after each method     │ │
│*│ │ call as an advice. The corresponding MP model may  │ │
│*│ │ look like the following.                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 2: Modeling Aspect-Oriented Paradigm"     │ │
│*│ │    from Auguston, M. "Monterey Phoenix System and  │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Kiczales, G., Lamping, J., Mehdbekar, A.,          │ │
│*│ │    Maeda, C., Lopes, C.V., Loingtier, J., Irwin.,  │ │
│*│ │    J. "Aspect-Oriented Programming", Proceedings   │ │
│*│ │    of the European Conference on Object-Oriented   │ │
│*│ │    Programming (ECOOP), Springer-Verlag LNCS 1241. │ │
│*│ │    June 1997.                                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, aspect-oriented paradigm;                │ │
│*│ │ coordination, event                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 13 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 40 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Aspect_Oriented_Paradigm

ROOT Main: (* ( M1 | M2 | do_something_else ) *);
ROOT PreAdvice: (* Prolog *);
ROOT PostAdvice: (* Epilog *);

COORDINATE
	$jp: ( M1 | M2 ) FROM Main,
	$a1: Prolog FROM PreAdvice,
	$a2: Epilog FROM PostAdvice

DO ADD
	$a1 PRECEDES $jp,
	$jp PRECEDES $a2;
OD;
