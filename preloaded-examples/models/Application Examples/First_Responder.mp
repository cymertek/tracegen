/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of First Responder                           │ │
│*│ │  Created by Jordan Bryant in May, 2016.            │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate unexpected emergent behavior in a   │ │
│*│ │ first responder scenario involving the             │ │
│*│ │ administation of a rescue medication (Narcan) to   │ │
│*│ │ an overdose victim.                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates the administration of      │ │
│*│ │ Narcan by bystanders in order to determine the     │ │
│*│ │ possible consequences of allowing or even          │ │
│*│ │ encouraging bystanders to administer medication in │ │
│*│ │ an overdose scenario.                              │ │
│*│ │                                                    │ │
│*│ │ This model is a draft snapshot of a high school    │ │
│*│ │ student's senior capstone project studying safety  │ │
│*│ │ issues pertaining to a proposed process for        │ │
│*│ │ layperson administration of a rescue medication    │ │
│*│ │ called Narcan (Bryant 2016). It produces various   │ │
│*│ │ possible scenarios that could emerge based on the  │ │
│*│ │ possible actions of bystanders and first           │ │
│*│ │ responders and their interactions with the victim. │ │
│*│ │ The original analysis goal was to determine the    │ │
│*│ │ time savings in having bystanders prepared to      │ │
│*│ │ administer the rescue medication, but an           │ │
│*│ │ unexpected behavior was found among the generated  │ │
│*│ │ traces that neither student nor mentor considered. │ │
│*│ │ For example, trace 6 prompted the idea to modify   │ │
│*│ │ the process to include the bystander marking the   │ │
│*│ │ victim to indicate the dose and time they          │ │
│*│ │ administered while waiting for the first           │ │
│*│ │ responders. Being a work in progress, this model   │ │
│*│ │ is incomplete, but this version of it was archived │ │
│*│ │ in order to capture the state of the model in      │ │
│*│ │ which the unexpected emergent behavior was first   │ │
│*│ │ observed.                                          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Bryant, Jordan (2016). "Using Monterey Phoenix to  │ │
│*│ │    analyze an alternative process for              │ │
│*│ │    administering Naloxone," mentored by Kristin    │ │
│*│ │    Giammarco (NPS) and Rick Schlegel (EMT).        │ │
│*│ │    Available online:                               │ │
│*│ │    http://scienceandmathacademy.com/academics/srt4/student_work/2016/bryant_jordan.pdf
│*│ │                                                    │ │
│*│ │ Giammarco, Kristin, and Kathleen Giles.            │ │
│*│ │    "Verification and validation of behavior models │ │
│*│ │    using lightweight formal methods." In           │ │
│*│ │    Disciplinary convergence in systems engineering │ │
│*│ │    research, pp. 431-447. Springer, Cham, 2018.    │ │
│*│ │    Available online:                               │ │
│*│ │    https://calhoun.nps.edu/handle/10945/58237      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, first responder; behavior, bystander;    │ │
│*│ │ behavior, unexpected                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
