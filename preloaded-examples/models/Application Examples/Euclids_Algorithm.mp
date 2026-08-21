/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Euclids Algorithm                         │ │
│*│ │  Created by Michael Collins in October, 2022.      │ │
│*│ │  Edited by Pamela Dyer and Kristin Giammarco in    │ │
│*│ │   October, 2022.                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To use MP to model an adaptation of the well-known │ │
│*│ │ Greatest Common Divisor (GCD) Algorithm by Euclid. │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This models Euclid's algorithm to compute a GCD    | |
│*│ │ Inspired by Leslie Lamports discussions about TLA+ │ │
|*| | The constraints handle undesirable traces in such a| | 
|*| | computation.                                       | |
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Leslie Lamport's Introduction to TLA+              | |
│*│ │ https://www.newsroom.hlf-foundation.org/newsroom/  | |
│*│ │ https://www.newsroom.hlf-foundation.org/newsroom/lectures/video/lecture-if-youre-not-writing-a-program-dont-use-a-programming-language.html
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, Euclid; GCD; Lamport;                    │ │
│*│ │ coordination, event; ENSURE, conditional           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1:  4 traces in less than 1 sec.             │ │
│*│ │ Scope 2: 10 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 22 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Euclids_Algorithm

ROOT GCD:   set_initial_value_for_x
            set_initial_Value_for_y

			(*
    			(  	x_has_become_greater_than_y
       				x_is_assigned_new_value_of_y_subtracted_from_x
       				y_does_not_change_value
    			|
       				y_has_become_greater_than_x
       				y_is_assigned_new_value_of_x_subtracted_from_y
       				x_does_not_change_value
    			|  
       				x_equals_y
    			)
			*)
;

IF #x_equals_y > 0 THEN

 ENSURE #x_equals_y == 1;
 ENSURE FOREACH $x: x_equals_y

   #x_has_become_greater_than_y AFTER $x == 0 AND

   #y_has_become_greater_than_x AFTER $x == 0;

FI;
