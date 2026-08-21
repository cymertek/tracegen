/*

Application of Monterey Phoenix Modeling to Manufacturing Product Systems
An example pre-dating MP-Firebird application that was used to generate scenarios
for separately estimating probability, time and cost of each of these scenarios.
MP version 4 may be used to conduct such analysis with its native capabilities.
Created by: John Palmer
August 2014

*/

SCHEMA Manufacturing_System

ROOT SYSTEM:	(* 	Incoming_Material
					Multi_Axis_Machine
					Media_Finish
					Send_to_Inspector
    
						(* 	Rejected
							Rework
							Send_to_Inspector 
						*)
    
						Accepted

					( ( Turning_Machine_1 
                        Milling_Machine_1 
                        Turning_Machine_2 
                        Milling_Machine_2 ) | 
                        
                        ( Multitask_1 Multitask_2 )
    				)
    
					Send_to_Inspector2
    
						(* 	Rejected2
							Rework2
							Send_to_Inspector2
						*)
    
						Accepted2

					Surface_Treatment
					Package_Part
					Ship_Part
				 *);
						
ROOT 	INSPECTOR:  (* <0..3> 	Inspect 
    							( Accept | Reject ) 
    				*);
					
		Inspect:	CheckPart ProvideAnswer;	

ROOT 	INSPECTOR2: (* <0..3> 	Inspect2
								( Accept2 | Reject2 ) 
					*);
					
		Inspect2:	CheckPart2 ProvideAnswer2;	



ROOT SysInsp: 	(* <1..3> 	Send_to_Inspector  
    						Inspect 
							( Reject Rejected  | Accept Accepted )
				*);


INSPECTOR, SysInsp 	SHARE ALL 	Inspect, Accept, Reject;
SysInsp, SYSTEM 	SHARE ALL 	Send_to_Inspector, Accepted, Rejected;


ROOT SysInsp2: 	(*<1..3> 	Send_to_Inspector2  
    						Inspect2 
							( Reject2 Rejected2  | Accept2 Accepted2 )
				*);


SysInsp2, SYSTEM 		SHARE ALL 	Send_to_Inspector2, Accepted2, Rejected2;
INSPECTOR2, SysInsp2 	SHARE ALL 	Inspect2, Accept2, Reject2;

