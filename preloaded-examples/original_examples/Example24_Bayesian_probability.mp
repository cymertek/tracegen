/* Example24.mp Bayesian attribute example

    Suppose there are 3 red and 2 green balls in a box. 
    We pick at random three balls, one at a time. 
    The result of the process can be denoted as RRR, RRG, or RGG, 
    representing sets of selected balls.

    The following MP schema demonstrates how to obtain all valid traces 
    and to calculate probabilities for the results.
    Bar chart in GLOBAL section summarizes the probabilities of all outcomes.
    
    Please notice that the trace Type 1 probability is calculated as 1/7 ~ 0.142857,
    since Type 1 assumes that probability of selecting an alternative is 
    constant for the whole derivation process.

    run for scope 1
*/
SCHEMA RedGreen

ATTRIBUTES{ number 	selection_probability, 
    				RRR_probability,
    				RRG_probability,
    				RGG_probability; };

ROOT Selection:
    /* there are precisely three ball selections */
    (+ <3> ( Select_Red | Select_Green ) +)

    /* possible selection configurations */
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
    TABS string s1, number n1;
    };

/* fill the Table with probabilities collected in GLOBAL attributes */
t1 <| s1: SAY("RRR"), n1: RRR_probability;
t1 <| s1: SAY("RRG"), n1: RRG_probability;
t1 <| s1: SAY("RGG"), n1: RGG_probability;


BAR CHART b{ TITLE ("Total outcome probabilities in all " #$$TRACE " traces");
    FROM t1; X_AXIS s1;
    };

SHOW b;
