/* Small Package Delivery

Taken from use case description in the Skyzer IM20 Mission Model 
(Non-Combatant Operations Scenario):

"Family traveling from PR to Florida in a 1984 Catalina 36 have an
emergency out on sea. A 40 year old father is diabetic and has ran [sic]
out of insulin and because he is the main sail operator, the family is
suck [sic] at sea until medical attention can arrived [sic]. The major
problem is that the USCG Cutter is four hours out on another mission, from
the last known location point of the sailboat last communication
beacon. But the there is a Navy ship in closer proximity with UAV
capabilities. The USS Fitzgerald is 75 nm from that last know location
point and has the needed medical supplies. USS Fitzgerald also has
UAV capabilities to transport the supplies in the required time line.
This Navy capability can provide the needed supplies within the
required time line without risk of placing the patient at risk of a
diabetic coma. The Navy’s UAV can fly out to the sailboat and drop
off the medical supplies until the USCG can arrived to transport
the family to safety.
Depends on: range, sea states, weather, visibility, day, Night. Is it
raining? Hailing?"

Non-combatant Scenario 1 authored by N. Roberts (Engility)
MP model authored by K. Giammarco (NPS) and D. Shifflett (NPS)

This model shows only two scenarios due to overloading constraints
(constraints that suppress entire branches of execution that a user
intended to permit).

Removing everything except the SCHEMA definition and the Air_Vehicle 
root (line 36 and lines 114-128) and running that model subset, one can 
see 6 event traces, one of which is unexpected: the Air_Vehicle drops 
the payload with no vessel in sight (trace 6).

*/

SCHEMA Small_Package_Delivery


/*-----------------------
  RESCUEE BEHAVIORS
-------------------------*/
ROOT Rescuee: { Victim, EPIRB };

      Victim: ( Receive_Payload
               	Emergency_Averted |
                Payload_Not_Received
                Diabetic_Coma	);

       EPIRB:;


/*-----------------------------
  MISSION COMMANDER BEHAVIORS
-------------------------------*/
ROOT Mission_Commander: ( Confirm_Vessel
                          ( Confirms_Drop_via_Video_Feed 			|

                              Confirms_Payload_Misses_Target 		) 	| 
    
    								Confirm_Not_Found 					)
                        Authorized_UAV_Return;



/*-----------------------------
  UAV OPERATOR BEHAVIORS
-------------------------------*/
ROOT UAV_Operator: [ Command_UAV_To_Drop_Payload ]
                   [ Release_UAV_to_Second_Location ]
                   Command_UAV_Return
                   Transfer_to_LOS_Communication
                   Command_UAV_to_Land
                   Turn_Off_UAV;

/***INTERACTIONS***/

COORDINATE $a: Confirm_Vessel               FROM Mission_Commander,
           $b: Command_UAV_To_Drop_Payload  FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: ( Confirms_Drop_via_Video_Feed |
                 Confirms_Payload_Misses_Target )  FROM Mission_Commander,
           $b: Release_UAV_to_Second_Location FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Authorized_UAV_Return   FROM Mission_Commander,
           $b: Command_UAV_Return      FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;



/*-----------------------------
  INMARSAT BEHAVIORS
-------------------------------*/
ROOT INMARSAT: Relay_Data_and_Comm_UAV_Communication;



/*-----------------------------
  Control Station BEHAVIORS
-------------------------------*/
ROOT Control_Station: Receive_Video;


/***INTERACTIONS***/

COORDINATE $a: Receive_Video                          FROM Control_Station,
           $b: ( Confirm_Vessel | Confirm_Not_Found ) FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;


/*-----------------------------
  Air Vehicle BEHAVIORS
-------------------------------*/
ROOT Air_Vehicle: Start_GPS_Navigation
                  Transit_to_Mission_Location
                  Detect_Beacon
                  ( <<0.90>> Locate_Vessel
                             Holds_over_Vessel 	|
                    <<0.10>> Vessel_Not_Found 	)
                  Transmit_Video
                  [ Receive_Command
                    Drop_Payload
                    ( <<0.98>> Payload_on_Target 		|
                      <<0.02>> Payload_Misses_Target	)
                  ]
                  
				  Return_to_Hold_Point
                  Shut_Down;


/***INTERACTIONS***/

COORDINATE $a: Relay_Data_and_Comm_UAV_Communication FROM INMARSAT,
           $b: Start_GPS_Navigation                  FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Transmit_Video                        FROM Air_Vehicle,
           $b: Receive_Video                         FROM Control_Station
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Command_UAV_To_Drop_Payload  FROM UAV_Operator,
           $b: Receive_Command              FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_on_Target            FROM Air_Vehicle,
           $b: Receive_Payload              FROM Rescuee
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_on_Target            FROM Air_Vehicle,
           $b: Confirms_Drop_via_Video_Feed FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_Misses_Target        FROM Air_Vehicle,
           $b: Payload_Not_Received         FROM Rescuee
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_Misses_Target          FROM Air_Vehicle,
           $b: Confirms_Payload_Misses_Target FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Command_UAV_Return      FROM UAV_Operator,
           $b: Return_to_Hold_Point    FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Return_to_Hold_Point             FROM Air_Vehicle,
           $b: Transfer_to_LOS_Communication    FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Turn_Off_UAV         FROM UAV_Operator,
           $b: Shut_Down            FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;


/***CONSTRAINTS***/

ENSURE #Locate_Vessel > 0 -> #Confirm_Vessel > 0;

ENSURE #Vessel_Not_Found > 0 -> #Confirm_Not_Found > 0;


/*-------------------------------------
  Launch and Recovery System BEHAVIORS
---------------------------------------*/

ROOT Launch_and_Recovery_System: { UCARS, RAST };

		UCARS:  Guide_UAV_To_Landing;

        RAST:   Grab_UAV;


/***INTERACTIONS***/

COORDINATE $a: Command_UAV_to_Land      FROM UAV_Operator,
           $b: Guide_UAV_To_Landing     FROM Launch_and_Recovery_System
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Guide_UAV_To_Landing FROM Launch_and_Recovery_System,
           $b: Grab_UAV             FROM Launch_and_Recovery_System
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Grab_UAV             FROM Launch_and_Recovery_System,
           $b: Turn_Off_UAV         FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

