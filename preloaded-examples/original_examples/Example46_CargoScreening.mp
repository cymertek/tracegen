/*	Cargo Screening process model
May 6, 2011, draft written by Mikhail Auguston, NPS, Monterey, CA
source:  
Department of Homeland Security 
Ofﬁce of Inspector General 
CBP's Container Security Initiative Has 
Proactive Management and Oversight but Future Direction Is Uncertain 
OIG-10-52 February 2010 

Error found: the original flowchart does not specify what happens if 
selection_has_not_been_accepted, I've added PhysicalExamination
and AnomalyResolution as a follow-up, but this scenario should be approved by the customer

MP-Firebird may be used at least for the following:
- generate all possible scenarios and inspect them manually, 
	this way it becomes possible to find out the deficiency pointed out above
-  typical assertion that may be verified: "if the cargo has been loaded, 
	was it always preceded by ThreatIsNotFound or No_high_risk_cargo_selected events?"
- typical query may be: "show all scenarios when Loading event does not happen"

*/

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

