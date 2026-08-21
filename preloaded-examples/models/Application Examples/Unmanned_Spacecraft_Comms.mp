/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Unmanned Spacecraft Comms                 │ │
│*│ │  Created by Cassie Nelson on the 4th of            │ │
│*│ │     October, 2015.                                 │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate and discuss discovery of emergent   │ │
│*│ │ behavior in a communication protocol for a         │ │
│*│ │ spacecraft docking with the International Space    │ │
│*│ │ Station (ISS).                                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model describes a spacecraft communication    │ │
│*│ │ system that works with the International Space     │ │
│*│ │ Station (ISS) for approach operations. The         │ │
│*│ │ communication link between a spacecraft and the    │ │
│*│ │ ISS is monitored through a frame counter called    │ │
│*│ │ the "Heartbeat". This model represents the         │ │
│*│ │ behavior of the Heartbeat while a Spacecraft is    │ │
│*│ │ approaching the ISS. A loss in communications      │ │
│*│ │ could result in a high consequence failure, such   │ │
│*│ │ as collision. Initially, Nelson found three valid  │ │
│*│ │ scenarios: both spacecraft and ISS register a      │ │
│*│ │ valid heartbeat and the approach continues         │ │
│*│ │ (trace 1), the spacecraft registers a valid        │ │
│*│ │ heartbeat but the ISS registers an invalid one and │ │
│*│ │ both switch to a redundant communication system    │ │
│*│ │ (trace 2), and both spacecraft and ISS register an │ │
│*│ │ invalid heartbeat in which case the operation is   │ │
│*│ │ aborted (trace 4). Upon inspecting these three     │ │
│*│ │ valid scenarios generated, it became clear that a  │ │
│*│ │ fourth scenario was missing from the               │ │
│*│ │ specification: the one in which the spacecraft     │ │
│*│ │ registers an invalid heartbeat and the ISS         │ │
│*│ │ registers a valid heartbeat, in which case the     │ │
│*│ │ operation should be aborted.  The model logic was  │ │
│*│ │ modified to admit this possibility (trace 3). This │ │
│*│ │ model provides inspiration for the following       │ │
│*│ │ requirement: “The ISS shall abort docking          │ │
│*│ │ operations with a spacecraft that has an invalid   │ │
│*│ │ heartbeat comparison, even if the ISS heartbeat    │ │
│*│ │ comparison is valid.”                              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Nelson, Cassie. “Modeling a spacecraft             │ │
│*│ │    communication system using Monterey Phoenix: a  │ │
│*│ │    systems engineering case study.” Master’s       │ │
│*│ │    Project,  Stevens Institute of Technology,      │ │
│*│ │    Hoboken, NJ. November 2015.                     │ │
│*│ │                                                    │ │
│*│ │ Giammarco, Kristin, and Kathleen Giles.            │ │
│*│ │    "Verification and validation of behavior models │ │
│*│ │    using lightweight formal methods." In           │ │
│*│ │    Disciplinary convergence in systems engineering │ │
│*│ │    research, pp. 431-447. Springer,                │ │
│*│ │    Cham, 2018.Available online:                    │ │
│*│ │    https://calhoun.nps.edu/handle/10945/58237      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, spacecraft; behavior, communication;     │ │
│*│ │ autonomous                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, 3, and 4.                     │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 20 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 84 traces in approx. 3.0 sec.             │ │
│*│ │ Scope 4: 340 traces in approx. 1.2 min.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

/*—————————————————————————————
 	 		  Actors
———————————————————————————————*/

SCHEMA Heartbeat

ROOT Spacecraft:	Receive_Heartbeat		
					(+  Echo_Heartbeat
						Receive_Incremented_Heartbeat	
						Compare_Received_Heartbeat_Values
						( SC_HB_Valid | SC_HB_Invalid )	+);

	SC_HB_Valid:	( Continue_Approach | Switch_to_Redundant_Comm_System );

	SC_HB_Invalid: 	Abort_Operations;
			

ROOT ISS: 	Generate_Heartbeat
			Send_Heartbeat
			(+	Receive_Echoed_Heartbeat	
				Increment_Heartbeat Send_Incremented_Heartbeat
            	Compare_Sent_and_Received_HB  
				( HB_Valid | HB_Invalid ) +);

	HB_Valid: 	( Continue_Approach | Abort_Operations );

	HB_Invalid: ( Switch_to_Redundant_Comm_System | Abort_Operations );

/*—————————————————————————————
 		        Interactions
———————————————————————————————*/

ISS, Spacecraft SHARE ALL 	Abort_Operations, 
							Switch_to_Redundant_Comm_System,
							Continue_Approach;

COORDINATE 	$a: Send_Heartbeat		FROM ISS,
			$b: Receive_Heartbeat	FROM Spacecraft
	DO ADD 	$a PRECEDES $b; OD;

COORDINATE 	$a: Echo_Heartbeat				FROM Spacecraft,
			$b: Receive_Echoed_Heartbeat 	FROM ISS
	DO ADD 	$a PRECEDES $b; OD;

COORDINATE 	$a: Send_Incremented_Heartbeat 		FROM ISS,
			$b: Receive_Incremented_Heartbeat 	FROM Spacecraft
	DO ADD 	$a PRECEDES $b; OD;
