/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Find Advisor                              │ │
│*│ │  Created by Kristin Giammarco in 2015.             │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show that human interaction and organizational  │ │
│*│ │ processes can be modeled using MP.                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Alternate behaviors for humans are described in    │ │
│*│ │ terms of possible decisions they could make. This  │ │
│*│ │ example models the process of a student finding an │ │
│*│ │ advisor for a potentially MP-related research      │ │
│*│ │ topic. To do so, it uses root events, composite    │ │
│*│ │ events, atomic events, "or" logic ( ... | ... ),   │ │
│*│ │ and COORDINATE statements. Users should inspect    │ │
│*│ │ this model when considering the process of finding │ │
│*│ │ a mentor, or looking to learn how to use           │ │
│*│ │ COORDINATE statements to make a model. Because the │ │
│*│ │ same modeling approach can be used for human       │ │
│*│ │ systems and technological systems, it becomes      │ │
│*│ │ possible to have integrated behavior models        │ │
│*│ │ containing both humans and technology to study the │ │
│*│ │ possible interactions among them.                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ None.                                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, finding advisor;                         │ │
│*│ │ human interactions modeling;                       │ │
│*│ │ behavior, human systems                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1 (there is no iteration in this     │ │
│*│ │ example, so increasing the scope will not produce  │ │
│*│ │ more scenarios).                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
