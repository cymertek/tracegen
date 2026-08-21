/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Agile Production Platform with Supply     │ │
│*│ │    Chain Interaction                               │ │
│*│ │  Created by Joshua Beaver in September, 2020.      │ │
│*│ │  Edited by Pamela Dyer in September, 2021.         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To show the fundamental goal of the "Agile         │ │
│*│ │ Production Platform" (APP), which is to act as an  │ │
│*│ │ intermediary between the customer and suppliers to │ │
│*│ │ build an ad-hoc supply chain where every supplier  │ │
│*│ │ has the technical knowledge, capacity, and         │ │
│*│ │ material on-hand to produce the component          │ │
│*│ │ correctly.                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using MP to find both      │ │
│*│ │ desired and undesired scenarios resulting from     │ │
│*│ │ interactions among supply chains. Raw material     │ │
│*│ │ suppliers, component suppliers, finished product   │ │
│*│ │ suppliers, the customer, and the APP are all taken │ │
│*│ │ into account. In general, the goal of the model is │ │
│*│ │ to check that each phase of supplier is able to    │ │
│*│ │ produce the expected product. Here the product is  │ │
│*│ │ a general term. A story of Expected Emergent       │ │
│*│ │ Behavior told over trace 14 (out of 55 at scope 1) │ │
│*│ │ is: the component supplier was still at maximum    │ │
│*│ │ capacity even though the APP pooled more suppliers │ │
│*│ │ at all levels of production, so the order was not  │ │
│*│ │ fulfilled (an Unfavorable Outcome). (This involved │ │
│*│ │ imagining an event change under the Customer from  │ │
│*│ │ receive to did not receive product). An example of │ │
│*│ │ Unexpected Emergent Behavior coming out of this    │ │
│*│ │ model is shown in trace 36: a nonconforming        │ │
│*│ │ material still making its way to the customer,     │ │
│*│ │ either through a miscommunication or lack of       │ │
│*│ │ inspection (also an Unfavorable Outcome).          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Appendix B in Beaver, Joshua. "Analyzing Emergent  │ │
│*│ │ Behavior of Supply Chains for Personal Protective  │ │
│*│ │ Equipment in Response to COVID-19." NPS Master's   │ │
│*│ │ Thesis, Monterey, CA: September 2021.              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, supply chain; coordination, event;       │ │
│*│ │ behavior, unexpected; behavior, emergent;          │ │
│*│ │ behavior, agile production platform                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 55 traces in less than 1 sec.             │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Agile_Production_Platform_Supply_Chain_Interaction

ROOT Customer:
							(*	submit_request_to_APP
                                receive_product
                            *);

ROOT Raw_Material_Supplier:	
							(*	receive_request_from_APP
    							(technical_expertise_to_make_product
                                    (material_on_hand 		
                                		(capacity_available
                                    		make_material 
                                    			(test_or_inspection_conducted		
                                            		(material_conforming		|
                                                    material_nonconforming		)	|
                                                test_or_inpsection_not_conducted	)
                                            	ship_material							|
                                        max_capacity									)	|
                                     material_out_of_stock									)	|
                                no_technical_expertise											)   
    						*);
                            

ROOT Component_Supplier:	
							(*	receive_request_from_APP
    							(technical_expertise_to_make_product
                                    (material_on_hand 		
                                		(capacity_available
                                    		make_material 
                                    			(test_or_inspection_conducted		
                                            		(material_conforming		|
                                                    material_nonconforming		)	|
                                                test_or_inpsection_not_conducted	)
                                            	ship_material							|
                                        max_capacity									)	|
                                     material_out_of_stock									)	|
                                no_technical_expertise											)   
    						*);

ROOT Finished_Product_Supplier:
							(*	receive_request_from_APP
    							(technical_expertise_to_make_product
                                    (material_on_hand 		
                                		(capacity_available
                                    		make_material 
                                    			(test_or_inspection_conducted		
                                            		(material_conforming		|
                                                    material_nonconforming		)	|
                                                test_or_inpsection_not_conducted	)
                                            	ship_material							|
                                        max_capacity									)	|
                                     material_out_of_stock									)	|
                                no_technical_expertise											)   
    						*);

ROOT Agile_Production_Platform:
							(*	receive_request_from_customer
                                submit_request_to_suppliers
                            *);

COORDINATE	$x:	ship_material FROM Raw_Material_Supplier,
    		$y: material_on_hand FROM Component_Supplier
    	DO ADD $x PRECEDES $y; OD;
COORDINATE	$x:	ship_material FROM Component_Supplier,
    		$y: material_on_hand FROM Finished_Product_Supplier
    	DO ADD $x PRECEDES $y; OD;
COORDINATE	$x:	submit_request_to_APP FROM Customer,
    		$y: receive_request_from_customer FROM Agile_Production_Platform
    	DO ADD $x PRECEDES $y; OD;
/*COORDINATE	$x:	ship_material FROM Finished_Product_Supplier,
    		$y: receive_product FROM Customer
    	DO ADD $x PRECEDES $y; OD;*/
COORDINATE	$x:	submit_request_to_suppliers FROM Agile_Production_Platform,
    		$y: receive_request_from_APP FROM Raw_Material_Supplier
    	DO ADD $x PRECEDES $y; OD;
COORDINATE	$x:	submit_request_to_suppliers FROM Agile_Production_Platform,
    		$y: receive_request_from_APP FROM Component_Supplier
    	DO ADD $x PRECEDES $y; OD;
COORDINATE	$x:	submit_request_to_suppliers FROM Agile_Production_Platform,
    		$y: receive_request_from_APP FROM Finished_Product_Supplier
    	DO ADD $x PRECEDES $y; OD;
