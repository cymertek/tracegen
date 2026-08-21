/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Dining Philosophers                       │ │
│*│ │  Created by Mikhail Auguston in 2015.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the extensive logic and problem      │ │
│*│ │ solving capabilities of MP, using the dining       │ │
│*│ │ philosophers problem as the topic.                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using COORDINATE, ENSURE,  │ │
│*│ │ and IF statements to come up with an answer to a   │ │
│*│ │ problem often used to illustrate synchronization   │ │
│*│ │ issues. The logic and problem solving potential of │ │
│*│ │ Monterey Phoenix is shown through its ability to   │ │
│*│ │ come up with the exhaustive number of solutions to │ │
│*│ │ a complex puzzle with some code and constraints.   │ │
│*│ │                                                    │ │
│*│ │ Five silent philosophers sit at a table around a   │ │
│*│ │ bowl of spaghetti. A fork is placed between each   │ │
│*│ │ pair of adjacent philosophers. It was originally   │ │
│*│ │ formulated in 1965 by Edsger Dijkstra.             │ │
│*│ │                                                    │ │
│*│ │ Each philosopher must alternately think and eat.   │ │
│*│ │ However, a philosopher can only eat spaghetti      │ │
│*│ │ when he has both left and right forks. Each fork   │ │
│*│ │ can be held by one philosopher only and so a       │ │
│*│ │ philosopher can use the fork only if it's not      │ │
│*│ │ being used by another philosopher. After he        │ │
│*│ │ finishes eating, he needs to put down both forks   │ │
│*│ │ so they become available to others. A philosopher  │ │
│*│ │ can grab the fork on his right or the one on his   │ │
│*│ │ left as they become available, but can't start     │ │
│*│ │ eating before getting both of them.                │ │
│*│ │                                                    │ │
│*│ │ Eating is not limited by the amount of spaghetti   │ │
│*│ │ remaining: assume an infinite supply. The problem  │ │
│*│ │ is how to design a discipline of behavior (a       │ │
│*│ │ concurrent algorithm) such that each philosopher   │ │
│*│ │ won't starve; i.e., can forever continue to        │ │
│*│ │ alternate between eating and thinking assuming     │ │
│*│ │ that any philosopher cannot know when others may   │ │
│*│ │ want to eat or think.                              │ │
│*│ │                                                    │ │
│*│ │ This MP model provides abstract specification of   │ │
│*│ │ correct behaviors, but does not provide            │ │
│*│ │ implementation details. Since MP supports          │ │
│*│ │ automated use case extraction, this model may be   │ │
│*│ │ used as a source of test cases for testing the     │ │
│*│ │ implementation.                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 25: Dining Philosophers." from            │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Dining philosophers problem." Wikipedia.          │ │
│*│ │    Wikimedia Foundation, August 6, 2021.           │ │
│*│ │    https://en.wikipedia.org/wiki/Dining_philosophers_problem
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, dining philosophers; riddles;            │ │
│*│ │ behavior, ring topology; event reshuffling;        │ │
│*│ │ BUILD block; isomorphism                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 2 and up. A philosopher cannot eat  │ │
│*│ │ with a single fork, so Scope 1 will produce zero   │ │
│*│ │ traces.                                            │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 0 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 4: 14 traces in less than 1 sec.             │ │
│*│ │ Scope 5: 30 traces in approx. 1.4 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Dining_Philosophers

ROOT Philosophers: {+<$$scope> 	Philosopher +};

Philosopher: 	(+ <1> think    eat   +)
/* Philosopher eats at least once, but is limited to reduce the number of traces */ ;

eat: { left_fork, right_fork };

ROOT Forks: {+ <$$scope>  Fork +};

Fork: (* <2> (left_fork | right_fork) *)
/* limit the number of fork use to reduce the number of traces,
    this in fact limits each Philosopher to one "eat" event */

/* Each fork is used at least once by each neighbor */
BUILD{ ENSURE #left_fork > 0 AND #right_fork > 0;}; 

/*  Assign forks to the Philosophers.
    Philosophers $p1 and $p2 share fork $f.

    Shift_left reshuffling takes the first event 
    from the beginning and puts it to the end of sequence.
        This adjusted thread is used to produce the ring topology,
    and to assign two neighbors $p1 and $p2 for sharing fork $f  */

COORDINATE          $p1: Philosopher,
    <SHIFT_LEFT>    $p2: Philosopher,
                    $f:  Fork 
DO  /*  Default sequence is adequate here: 
    the order of fork use in Philosopher and in Fork are the same. */
	$p1, $f SHARE ALL right_fork;
	$p2, $f SHARE ALL left_fork;
OD;

/* to avoid deadlocks 'eat' events competing for resources are put in order. */
COORDINATE 		$e1: eat
DO 	COORDINATE 	$e2: eat 
    DO
        IF EXISTS	$f1: (left_fork | right_fork) FROM $e1,
                    $f2: (left_fork | right_fork) FROM $e2
                    ($f1 PRECEDES $f2) 
        THEN
                ADD $e1 PRECEDES $e2;
        FI;
    OD;
OD;

/* Ensure that both forks can be used simultaneously */
COORDINATE 		$e: eat
DO 	COORDINATE 	$l: left_fork  FROM $e,
                $r: right_fork FROM $e
    DO
    /* MAY_OVERLAP $x $y is an abbreviation for NOT($x BEFORE $y OR $y BEFORE $x) */
        ENSURE MAY_OVERLAP $l $r;
    OD;
OD;
