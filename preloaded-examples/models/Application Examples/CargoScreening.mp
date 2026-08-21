/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Cargo Screening                           │ │
│*│ │  Created by Mikhail Auguston on the 6th of May,    │ │
│*│ │     2011.                                          │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate a model using a single long chain of │ │
│*│ │ logic, in this case outlining a cargo screening    │ │
│*│ │ process.                                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using composite statements │ │
│*│ │ under roots to make a long chain of logic. This    │ │
│*│ │ makes sense for models where 1 individual or       │ │
│*│ │ machine is doing many tasks. Users should remember │ │
│*│ │ that multiple roots should be used if multiple     │ │
│*│ │ people or objects are performing these actions,    │ │
│*│ │ but use composite statements when one action leads │ │
│*│ │ to several more.                                   │ │
│*│ │                                                    │ │
│*│ │ An error that was found was that the original      │ │
│*│ │ flowchart does not specify what happens if         │ │
│*│ │ selection_has_not_been_accepted; I've added        │ │
│*│ │ PhysicalExamination and AnomalyResolution as a     │ │
│*│ │ possible follow on events in this case but this    │ │
│*│ │ scenario should be approved by the customer.       │ │
│*│ │                                                    │ │
│*│ │ MP-Firebird may be used at least for the           │ │
│*│ │ following:                                         │ │
│*│ │    - generate all possible scenarios and inspect   │ │
│*│ │      them manually, this way it becomes possible   │ │
│*│ │      to find out the deficiency pointed out above  │ │
│*│ │    - typical assertion that may be verified: "if   │ │
│*│ │      the cargo has been loaded, was it always      │ │
│*│ │      preceded by ThreatIsNotFound or               │ │
│*│ │      No_high_risk_cargo_selected events?"          │ │
│*│ │    - typical query may be: "show all scenarios     │ │
│*│ │      when Loading event does not happen"           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Skinner, Richard. "CBP's Container Security        │ │
│*│ │ Initiative Has Proactive Management and Oversight  │ │
│*│ │ but Future Direction Is Uncertain (OIG-10-52)."    │ │
│*│ │ Office of Inspector General, Department of         │ │
│*│ │ Homeland Security. February 3, 2010.               │ │
│*│ │ https://www.oig.dhs.gov/assets/Mgmt/OIG_10-52_Feb10.pdf
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, cargo screening process;                 │ │
│*│ │ graph, flowchart                                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 6 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA CargoScreening

ROOT CargoScreeningProcess:  	Screening 	Targeting ;

Screening:  CBP_Officers_analyze_shipping_information_to_identify_high_risk_cargo; 

Targeting : CBP_Officers_review_the_shipping_information 
	    CBP_Officers_select_high_risk_cargo_to_be_presented_for_inspection
	    ( High_risk_cargo_selected 		Inspection   |
	      No_high_risk_cargo_selected 	Loading
		);

Inspection: ( selection_has_been_accepted 
 	      the_cargo_is_scanned_using_large_scale_NII_equipment
	      Anomaly_detection_and_processing |

	/*this branch is missing in the originalal document! 	*/
	      selection_has_not_been_accepted 
	      PhysicalExamination 
	      AnomalyResolution  		  );

Anomaly_detection_and_processing: AnomalyDetection 
 				  ( ThreatIsNotFound 	Loading |
				    AnomalyIsFound 
				    PhysicalExamination 
				    AnomalyResolution 		  );

AnomalyDetection: CBP_Officers_or_host_country_officials_identify_anomalies_in_the_x_ray_image;
 
PhysicalExamination:  CBP_Officers_or_host_country_officials_open_containers_to_locate_anomaly;

AnomalyResolution:  Officials_determine_if_the_anomaly_presents_a_threat
			( ThreatIsNotFound 	Loading   |
			  ThreatIsFound 	Resolution );

Resolution:	Officials_take_appropriate_steps_to_resolve_the_threat; 

Loading: 	The_container_is_loaded_onto_the_cargo_ship;

