/* 	Example 16, model of the spiral software process
    
    This example also illustrates how Melvin Conway's law 
    can be modeled in MP: "organizations which design systems ... 
    are constrained to produce designs which are copies of the 
    communication structures of these organizations."

    run scope up to 5
======================================*/

SCHEMA spiral

ROOT Stakeholders:
	Initial_communication_with_stakeholders
	Prototype_demonstration_to_stakeholders
	(* 	Stakeholders_are_not_satisfied
    	Prototype_demonstration_to_stakeholders *)
	Stakeholders_are_satisfied;

ROOT Spiral_process: 
		Initial_communication_with_stakeholders
		Initial_requirements
		Initial_design
		Prototype_demonstration_to_stakeholders
		(* One_iteration *)
		Stakeholders_are_satisfied
		Delivery_of_the_system;

One_iteration: 
		Stakeholders_are_not_satisfied
		Adjust_requirements
		Redesign
		Prototype_demonstration_to_stakeholders;

Initial_design:
		Architecture_design
		Detailed_design
		Coding
		Testing;

Redesign:
		[ Architecture_redesign ] /* not always needed */
		Detailed_redesign
		Coding
		Testing;

Stakeholders, Spiral_process SHARE ALL 	
	Initial_communication_with_stakeholders,
	Prototype_demonstration_to_stakeholders,
	Stakeholders_are_not_satisfied, 
	Stakeholders_are_satisfied;

ROOT Architect:
	Initial_communication_with_stakeholders
	Initial_requirements
	Architecture_design
	Prototype_demonstration_to_stakeholders
	(* 	Adjust_requirements
    	[ Architecture_redesign ] 
    	Prototype_demonstration_to_stakeholders *);

Architect, Spiral_process SHARE ALL 
	Initial_communication_with_stakeholders,
	Initial_requirements,
	Architecture_design,
	Prototype_demonstration_to_stakeholders,
	Adjust_requirements,
    Architecture_redesign;
    	 
ROOT Developers:
		Detailed_design
		Coding
		Testing
		(* 	Detailed_redesign
            Coding
			Testing 	*);

Developers, Spiral_process SHARE ALL
			Detailed_design,
			Detailed_redesign,
            Coding,
			Testing;
