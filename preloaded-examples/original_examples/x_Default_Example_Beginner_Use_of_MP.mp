/* A Simple Model of Beginner MP-Firebird Use
created by K.Giammarco 2021-02-08

This model provides an orientation for those just getting started using 
MP-Firebird.  This text editor pane allows you to compose and edit code 
in the high-level MP language.  Press the Run button to generate event 
traces from the code, then inspect the results in the center pane. Use 
the far right pane to navigae the resulting traces.  Use the scope slider 
bar next to the Run button to control the number of loop iterations.  

ROOT A: B C;	A is a root event that includes events B followed by C
( B | C )		Alternative events B or C (but not both together in the 
				same trace)
(* B *) 		iterate B zero or more times
{ B , C } 		B and C are unordered

Experiment with this model by running it at scopes 1, 2, 3, 4 and 5.  
You may also make changes to this model and run it with your changes. 
Save your model using the EXPORT button ("Code" exports a .mp text file 
of the contents of the text editor, and "Code and Event Trace" exports 
the contents of the text editor plus the graphs and any changes you made 
to the graph element positions. */


SCHEMA Beginner_Use_of_MP


/* Actor Behaviors */

ROOT User:  (	Import_existing_model					|
    
				Define_problem_of_interest
				Create_new_MP_model 
				Save_model 								)

                Run_the_model
				Inspect_scenarios
				(* 	Find_issue
               	 	Edit_MP_model
                    Save_model_copy
               		Rerun_the_model
               		Reinspect_scenarios *) 

            Find_all_scenarios_acceptable;

                            
ROOT MP_Firebird_Tool: { User_Interface, NPS_Server };

	User_Interface:
		(* Receive_run_command	
		   Send_model_for_processing
		   Display_scenarios *);

	NPS_Server:	(* 	Generate_scenarios
        			Send_scenarios *); 
			

/* Interactions */

COORDINATE 	$a: ( Run_the_model	| Rerun_the_model ),
			$b:   Receive_run_command 					
	DO 	ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Send_model_for_processing, $b: Generate_scenarios						
	DO 	ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Send_scenarios, $b: Display_scenarios							
	DO 	ADD $a PRECEDES $b; OD;

COORDINATE 	$a: Display_scenarios,				
			$b: ( Inspect_scenarios | Reinspect_scenarios )
	DO 	ADD $a PRECEDES $b; OD;


/*Additional Constraints */

/*Assumption that existing model has no verification issues. */
ENSURE #Import_existing_model >=1 -> #Find_issue == 0;


/* Trace annotations */

IF #Find_issue >1 THEN 
	SAY( #Find_issue " issues were discovered");

	ELSE 	IF #Find_issue ==1 THEN 
			SAY( #Find_issue " issue was discovered");
			FI;
FI;