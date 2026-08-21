/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Spiral Software Process                   │ │
│*│ │  Created by Mikhail Auguston in 2018.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate event sharing in order to model the  │ │
│*│ │ spiral software development process.               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates the usage of shared events │ │
│*│ │ to model the spiral software process to develop a  │ │
│*│ │ prototype and release a product. Users may use     │ │
│*│ │ this model to learn about SHARE ALL usage to make  │ │
│*│ │ connections between roots. This example also       │ │
│*│ │ illustrates how Melvin Conway's law can be modeled │ │
│*│ │ in MP: "organizations which design systems ... are │ │
│*│ │ constrained to produce designs which are copies of │ │
│*│ │ the communication structures of these              │ │
│*│ │ organizations."                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ None.                                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, spiral software process; event sharing   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 7 traces in less than 1 sec.              │ │
│*│ │ Scope 3: 15 traces in approx. 1.6 sec.             │ │
│*│ │ Scope 4: 31 traces in approx. 10 sec.              │ │
│*│ │ Scope 5: 63 traces in approx. 1.0 min.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Spiral_Software_Development_Process

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
