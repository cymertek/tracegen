/* A first responder scenario involving the administation of a rescue 
medication (Narcan) to an overdose victim by a First Responder or a 
Bystander.  

Create by J. Bryant, May 2016

The model was developed to compare response times, but unexpected 
scenarios emerged that was previously not considered.  Trace 6 and others
show a double administration of Narcan by both the bystander and the first 
responder.

*/

SCHEMA Narcan_Administration

ROOT OverdoseVictim: 
	overdose_on_and_opioid
	(breathing_is_supressed | stops_breathing)
	lose_consiousness
	receives_Narcan
	(recovers_in_hospital | dies);

ROOT Bystander:
	takes_notice

	(call_911|have_another_bystander_call_911)
		
	(Carrying_Narcan | Not_Carrying_Narcan);
		Carrying_Narcan: 
				administer_Narcan_while_on_line;
			Not_Carrying_Narcan:
				follow_the_operators_instructions;
					
ROOT FirstResponder:
	receives_911_call
	responds_to_scene

	(Narcan_was_administered|Narcan_was_not_administered);
		Narcan_was_administered:
			get_the_patient_to_hospital;
		Narcan_was_not_administered: 
			administer_Narcan
			get_the_patient_to_hospital;

COORDINATE
	$a:(administer_Narcan_while_on_line | Narcan_was_administered) FROM Bystander,
	$b:receives_Narcan FROM OverdoseVictim
	DO ADD $a PRECEDES $b; OD;


COORDINATE
	$a:(call_911|have_another_bystander_call_911) FROM Bystander,
	$b:receives_911_call FROM FirstResponder
	DO ADD $a PRECEDES $b; OD;

COORDINATE
	$a:get_the_patient_to_hospital FROM FirstResponder,
	$b:recovers_in_hospital FROM OverdoseVictim
	DO ADD $a PRECEDES $b; OD;
