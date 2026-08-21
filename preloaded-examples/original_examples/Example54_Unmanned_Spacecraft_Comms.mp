/* Heartbeat.mp
October 4, 2015
Created by: C. Nelson
	
The communication link between a spacecraft and the ISS is monitored
through a frame counter called the "Heartbeat". This model represents
the behavior of the Heartbeat while a Spacecraft is approaching 
the ISS.

Run for scope 1 and up. 
 
*/

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
