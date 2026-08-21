/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Small Package Delivery, Baseline Case              │ │
│*│ │  Created by Kristin Giammarco and David Shifflett  │ │
│*│ │  last edited on the 13th of August, 2018           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To provide an MP transcription of activities from  │ │
│*│ │ a SysML swim lanes activity diagram (single        │ │
│*│ │ phase).                                            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Taken from use case description in the Skyzer IM20 │ │
│*│ │ Mission Model:                                     │ │
│*│ │ "Family traveling from PR to Florida in a 1984 	 │ │
│*│ │ Catalina 36 have an emergency out on sea. A 40     │ │
│*│ │ year old father is diabetic and has run out of     │ │
│*│ │ insulin and because he is the main sail operator,  │ │
│*│ │ the family is stuck at sea until medical           │ │
│*│ │ attention can arrive. The major problem is that    │ │
│*│ │ the USCG Cutter is four hours out on another       │ │
│*│ │ mission, from the last known location point of the │ │
│*│ │ sailboat last communication beacon. But the there  │ │
│*│ │ is a Navy ship in closer proximity with UAV        │ │
│*│ │ capabilities. The USS Fitzgerald is 75 nm from     │ │
│*│ │ that last know location point and has the needed   │ │
│*│ │ medical supplies. USS Fitzgerald also has UAV      │ │
│*│ │ capabilities to transport the supplies in the      │ │
│*│ │ required time line.  This Navy capability can      │ │
│*│ │ provide the needed supplies within the required    │ │
│*│ │ time line without risk of placing the patient at   │ │
│*│ │ risk of a diabetic coma. The Navy’s UAV can fly    │ │
│*│ │ out to the sailboat and dropoff the medical        │ │
│*│ │ supplies until the USCG can arrived to transport   │ │
│*│ │ the family to safety. Depends on: range, sea       │ │
│*│ │ states, weather, visibility, day, Night. Is it     │ │
│ │ │ raining? Hailing?"                                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Transit/Navigate Task in "Non-combatant Scenario 1"│ │
│*│ │ 	authored by Nataki Roberts, 2017                 │ │  
│*│ │ "Skyzer IM20 Mission Model (Non-Combatant          │ │
│*│ │ Operations Scenario)" authored by Nataki Roberts   │ │
│*│ │ in Giammarco, K; Carlson, C., Blackburn, M.        │ │
│*│ │ "Verification and Validation (V&V) of System       │ │
│*│ │ Behavior Specifications." Final Technical Report   │ │
│*│ │ SERC-2018-TR-116; Systems Engineering Research     │ │
│*│ │ Center: Hoboken, NJ, USA, 2018. Available online:  │ │
│*│ │ https://apps.dtic.mil/sti/citations/AD1063328      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, UAV; Skyzer, autonomous                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA Small_Package_Delivery_Phase_3_Transit_Navigate


/*-----------------------
  RESCUEE BEHAVIORS
-------------------------*/
ROOT Rescuee: { Victim, EPIRB };

	Victim: Receive_Payload;
	EPIRB:;


/*-----------------------------
  MISSION COMMANDER BEHAVIORS
-------------------------------*/
ROOT Mission_Commander: Confirm_Vessel
                        Confirms_Drop_via_Video_Feed
                        Authorized_UAV_Return;


/*-----------------------------
  UAV OPERATOR BEHAVIORS
-------------------------------*/
ROOT UAV_Operator: Command_UAV_To_Drop_Payload
                   Release_UAV_to_Second_Location
                   Command_UAV_Return
                   Transfer_to_LOS_Communication
                   Command_UAV_to_Land
                   Turn_Off_UAV;

/***INTERACTIONS***/

COORDINATE $a: Confirm_Vessel               FROM Mission_Commander,
           $b: Command_UAV_To_Drop_Payload  FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Confirms_Drop_via_Video_Feed   FROM Mission_Commander,
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
  CONTROL STATION BEHAVIORS
-------------------------------*/
ROOT Control_Station: Receive_Video;

/***INTERACTIONS***/

COORDINATE $a: Receive_Video	FROM Control_Station,
           $b: Confirm_Vessel	FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

/*-----------------------------
  AIR VEHICLE BEHAVIORS
-------------------------------*/
ROOT Air_Vehicle: Start_GPS_Navigation
                  Transit_to_Mission_Location
                  Detect_Beacon
                  Locate_Vessel
                  Holds_over_Vessel
                  Transmit_Video
                  Receive_Command
                  Drop_Payload
                  Return_to_Hold_Point
                  Shut_Down;

/***INTERACTIONS***/

COORDINATE $a: Relay_Data_and_Comm_UAV_Communication FROM INMARSAT,
           $b: Start_GPS_Navigation                  FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Transmit_Video         FROM Air_Vehicle,
           $b: Receive_Video          FROM Control_Station
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Command_UAV_To_Drop_Payload  FROM UAV_Operator,
           $b: Receive_Command              FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Drop_Payload           FROM Air_Vehicle,
           $b: Receive_Payload        FROM Rescuee
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Drop_Payload                 FROM Air_Vehicle,
           $b: Confirms_Drop_via_Video_Feed FROM Mission_Commander
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

/*-----------------------------
  LAUNCH AND RECOVERY SYSTEM BEHAVIORS
-------------------------------*/
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
