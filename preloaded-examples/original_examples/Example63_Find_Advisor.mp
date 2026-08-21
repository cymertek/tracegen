/* example63_Find_Advisor.mp
	modeling human interactions
	
Human interaction and organizational processes can be modeled as well as technological
system and subsystem interactions.

In this example, the process of a student finding an advisor for a potentially 
MP-related research topic is modeled.  Alternate behaviors for humans are described in
terms of possible decisions they could make.

Because the same modeling approach can be used for human systems and technological systems, 
it becomes possible to have integrated behavior models containing both humans and 
technology to study the possible interactions among them.

Run for scope 1 (there is no iteration in this example, so increaasing the scope will not 
produce more scenarios). 

The "Sequence" or "Swim Lanes" layouts are the most appropriate for browsing traces here. 
The "Sequence" mode yields views very similar to the UML or SysML Sequence Diagrams. 

*/


/*—————————————————————————————
 	 		  Actors
———————————————————————————————*/
SCHEMA FindAdvisor

ROOT Student:	Hear_about_MP
                Get_intrigued
                Check_out_website
				Try_out_MP_modeling
                ( Like_MP | Decide_MP_not_for_me );

       Like_MP: Email_Advisor
                Discuss_research_interests
                ( Do_an_awesome_MP_project | Find_another_approach );

ROOT Advisor:  ( Set_up_meeting
                 Discuss_research_interests
                 ( Assess_MP_as_a_good_fit Advise_an_awesome_MP_project | 
                   Recommend_another_approach ) |
	             Does_something_else );

/*—————————————————————————————
 		        Interactions
———————————————————————————————*/

COORDINATE 	$a: Email_Advisor		FROM Student,
		$b: Set_up_meeting		FROM Advisor
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Discuss_research_interests  FROM Student,
		$b: ( Assess_MP_as_a_good_fit | Recommend_another_approach ) FROM Advisor
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Assess_MP_as_a_good_fit  	FROM Advisor,
		$b: Do_an_awesome_MP_project  	FROM Student
	DO ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Recommend_another_approach  FROM Advisor,
		$b: Find_another_approach  	FROM Student
	DO ADD $a PRECEDES $b; OD;

Student, Advisor SHARE ALL Discuss_research_interests;