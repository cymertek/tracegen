/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 18. Model of Ball Selection with           │ │
│*│ │ Conditional Probability                            │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to obtain the conditional       │ │
│*│ │ probability of an event appearing within a given   │ │
│*│ │ trace.                                             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This behavior model demonstrates how to compute    │ │
│*│ │ probabilities for events that depend on other      │ │
│*│ │ events before it in a given trace (conditional     │ │
│*│ │ probability). The idea that the order in which     │ │
│*│ │ activities are performed may affect the way the    │ │
│*│ │ probabilities of these activities are calculated   │ │
│*│ │ is based on Bayesian logic.                        │ │
│*│ │                                                    │ │
│*│ │ Suppose there are 3 red and 2 green balls in a     │ │
│*│ │ box. We pick at random three balls, one at a time. │ │
│*│ │ What is the probability for each combination of    │ │
│*│ │ Red and Green balls?                               │ │
│*│ │                                                    │ │
│*│ │ The following MP schema demonstrates how to obtain │ │
│*│ │ all valid traces and calculate probabilities for   │ │
│*│ │ the results.                                       │ │
│*│ │                                                    │ │
│*│ │ Please notice that the trace Type 1 probability is │ │
│*│ │ calculated as 1/7 ~ 0.142857, since Type 1 assumes │ │
│*│ │ that probability of selecting an alternative is    │ │
│*│ │ constant for the whole derivation process. With    │ │
│*│ │ conditional probability (Type 2), the probability  │ │
│*│ │ for selecting an alternative is not constant and   │ │
│*│ │ must be computed in the body of the schema. Notice │ │
│*│ │ that the trace probabilities in the SAY            │ │
│*│ │ annotations on each of the 7 traces still sum to   │ │
│*│ │ 1, but the probability for the event representing  │ │
│*│ │ the trace outcome was computed based on the        │ │
│*│ │ combination of the events before it in the trace.  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 32: Event probability calculations" from  │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ event attribute, number; probability, Type 2;      │ │
│*│ │ probability, Bayesian                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 7 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Red_Green

ATTRIBUTES{ number 	selection_probability, 
    				RRR_probability,
    				RRG_probability,
    				RGG_probability; };

ROOT Selection:
    /* there are precisely three ball selections */
    (+ <3> ( Select_Red | Select_Green ) +)

    /* possible ball selection configurations (R for red, 
       G for green) */
    ( RRR | RRG | RGG )
;

/* Constraints to shape the valid traces */
ENSURE  (#RRR == 1 <-> #Select_Red == 3) AND
        (#RRG == 1 <-> #Select_Red == 2) AND
        (#RGG == 1 <-> #Select_Red == 1);

/* Attribute calculations are done here */
COORDINATE  $res: ( RRR | RRG | RGG )
DO
    /* prepare for further calculations */
    selection_probability:= 1; 

    COORDINATE $s: ( Select_Red | Select_Green )
    DO 
    /* Probability of the result depends on the ball selection order */
        IF $s IS  Select_Red THEN 
            /* probability to select Red ball is:
               (number of Red balls available / total number of available balls) */
            selection_probability *:=
				(3 - #Select_Red BEFORE $s)/(5 - #( Select_Red | Select_Green ) BEFORE $s);
        ELSE 
            /* probability to select Green ball */
            selection_probability *:= 
				(2 - #Select_Green BEFORE $s)/(5 - #( Select_Red | Select_Green ) BEFORE $s);
        FI;
    OD;

    /* Report the results */
    SAY( "Probability of result " $res " was " selection_probability);
OD;

    IF #Select_Red == 1 THEN GLOBAL.RGG_probability +:=  selection_probability; FI;
    IF #Select_Red == 2 THEN GLOBAL.RRG_probability +:=  selection_probability; FI;
    IF #Select_Red == 3 THEN GLOBAL.RRR_probability +:=  selection_probability; FI;

GLOBAL
TABLE t1{
    TABS string outcome, number outcome_probability;
    };

/* fill the Table with probabilities collected in GLOBAL attributes */
t1 <| outcome: SAY("RRR"), outcome_probability: RRR_probability;
t1 <| outcome: SAY("RRG"), outcome_probability: RRG_probability;
t1 <| outcome: SAY("RGG"), outcome_probability: RGG_probability;


BAR CHART b{ TITLE ("Total outcome probabilities in all " #$$TRACE " traces");
    FROM t1; X_AXIS outcome;
    };

SHOW b;
