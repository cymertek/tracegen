/* Example39    turtles.mp
 
 Demonstration of the benefits for complete
 example set generation in MP.
 

 Three turtles are moving on a desert plain, all in the same direction.
 The first has been asked: "What do you see?" It answered:   
 "I see nobody before me and two turtles behind." The second turtle has been 
 asked the same question: "What do you see?" and answered 
 "I see one turtle before me and one behind." When the third turtle 
 is asked the same question, it answers: "I see one turtle before 
 me and one behind." How could that be?
 
Don't try to construct a non-Euclidean geometry to 
 accommodate the possible turtle configuration. A person with common sense 
 after a short moment of time will say: "The third is lying!" The 
 reaction will be: "Ahh, yes! But wait, maybe the first is lying, or the second, 
 or all three of them. It becomes too complicated...."
 
 Now it is time to use MP to obtain all possible scenarios for that story.
 
 Here it is. Run for scope 1.
 There are 13 possible scenarios, and none when all three 
 are telling the truth.
 
 ==================================*/
SCHEMA Turtles

neighbors: { (nobody_before  | one_before  | two_before ),
    		 (nobody_behinds | one_behinds | two_behinds)  }
BUILD{
    /* no more than one of two_before or two_behinds */
    ENSURE (#two_before + #two_behinds) < 2 	AND
    (#two_before == 1 -> #nobody_behinds == 1)	AND
    (#two_behinds == 1 -> #nobody_before == 1) ;
    };

ROOT Turtle_1: neighbors (Lying | Telling_the_truth)
BUILD{
    ENSURE (#Telling_the_truth == 1 <-> 
        		#nobody_before == 1 AND #two_behinds == 1);
    };

ROOT Turtle_2: neighbors (Lying | Telling_the_truth)
BUILD{
    ENSURE (#Telling_the_truth == 1 <-> 
        		#one_before == 1 AND #one_behinds == 1);
    };

ROOT Turtle_3: neighbors (Lying | Telling_the_truth)
BUILD{
    ENSURE (#Telling_the_truth == 1 <-> 
        		#one_before == 1 AND #one_behinds == 1);
    };

/*=============================== 
	global constraints 
=================================*/
/* ensure the shape of the pack 
---------------------------------*/
ENSURE FOREACH $t1: $$ROOT 
	(#two_before FROM $t1 > 0 -> EXISTS DISJ $t2: $$ROOT, $t3: $$ROOT 
        	$t1 != $t2 AND $t1 != $t3 AND
        
        		/* $t1 is the root of upward fork */
        	( (#one_behinds FROM $t2 == 1 AND #one_behinds FROM $t3 == 1) OR
                
                /* $t1 is the bottom of vertical line */
        	  (#one_behinds FROM $t2 == 1 AND #one_behinds FROM $t2 == 1 AND 
                  #two_behinds FROM $t3 == 1 )
            )
    ); 
        
ENSURE FOREACH $t1: $$ROOT 
	(#two_behinds FROM $t1 > 0 -> EXISTS DISJ $t2: $$ROOT, $t3: $$ROOT 
        	$t1 != $t2 AND $t1 != $t3 AND 
        
             	/* $t1 is the top of downward fork */
        	( (#one_before FROM $t2 == 1 AND #one_before FROM $t3 == 1) OR
        
                /* $t1 is the top of vertical line */
        	  (#one_behinds FROM $t2 == 1 AND #one_behinds FROM $t2 == 1 AND 
                  #two_before FROM $t3 == 1 )
            )
    ); 

/* turtles form either a fork or a line */
/*======================================*/
ENSURE  /* fork upward */
		#two_before == 1 	AND 
		#one_behinds == 2 	AND
		#one_before == 0 	AND
		#two_behinds == 0 	AND
		#nobody_before == 2 AND
		#nobody_behinds == 1 	OR

		/* fork downward */
		#two_behinds == 1 	AND 
		#one_before == 2 	AND
		#one_behinds == 0 	AND
		#two_before == 0 	AND 	
		#nobody_before == 1 AND
		#nobody_behinds == 2 	OR

		/* vertical */
 		#two_behinds == 1 	AND  
		#one_before == 1 	AND 
		#one_behinds == 1 	AND 
		#two_before == 1 		OR

		/* parallel */
		#nobody_behinds == 3 AND
		#nobody_before == 3
;
/*-------------------------------------------------------*/
IF #two_before == 1 AND #one_behinds == 2 AND #one_before == 0 THEN
		SAY("form fork upward"); FI;

IF #two_behinds == 1 AND #one_before == 2 AND #one_behinds == 0 THEN
		SAY("form fork downward"); FI;

    
IF #two_behinds == 1 AND #one_before == 1 AND 
	#one_behinds == 1 AND #two_before == 1 THEN 
		SAY("form vertical line"); FI;

IF #nobody_behinds == 3 THEN
		SAY("moving parallel"); FI;

IF #Lying == 0 THEN SAY("All three are telling truth!"); MARK; 
ELSE SAY( #Lying " are lying"); FI;
