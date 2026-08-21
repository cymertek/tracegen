/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Small Package Delivery, Creative Expansion         │ │
│*│ │  Created by Kristin Giammarco and David Shifflett  │ │
│*│ │  last edited on the 30th of August, 2018           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To expand the Small Package Delivery Baseline Case │ │
│*│ │ to include plausible alternative event flows.      │ │
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
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 12 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 16 traces in 1.55 sec.                    │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA Small_Package_Delivery_Phase_3_Transit_Navigate_Expanded


/*-----------------------
  RESCUEE BEHAVIORS
-------------------------*/

ROOT Rescuee: { Victim, EPIRB };

      Victim: (	Receive_Payload
               	Emergency_Averted    |
          
              	Payload_Not_Received
               	Diabetic_Coma		 );

       EPIRB:;


/*-----------------------------
  MISSION COMMANDER BEHAVIORS
-------------------------------*/
ROOT Mission_Commander: Receive_Video
                        (* Confirm_Continue_Search
                           Receive_Video			*)
                       
                        ( Confirm_Vessel
            
                          ( Confirms_Drop_via_Video_Feed 	|
                            Confirms_Payload_Misses_Target 	) 
              
                          		| Confirm_Not_Found
                          		| Confirm_Bingo_Fuel
                        )

                        Authorized_UAV_Return;


/*-----------------------------
  UAV OPERATOR BEHAVIORS
-------------------------------*/
ROOT UAV_Operator: (* Command_UAV_Continue_Search *)
                   [ Command_UAV_To_Drop_Payload ]
                   [ Release_UAV_to_Second_Location ]
                   Command_UAV_Return
                   Transfer_to_LOS_Communication
                   Command_UAV_to_Land
                   Turn_Off_UAV;

/***INTERACTIONS***/

COORDINATE $a: Confirm_Vessel               FROM Mission_Commander,
           $b: Command_UAV_To_Drop_Payload  FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Confirm_Continue_Search      FROM Mission_Commander,
           $b: Command_UAV_Continue_Search  FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Confirm_Not_Found              FROM Mission_Commander,
           $b: Release_UAV_to_Second_Location FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Authorized_UAV_Return   FROM Mission_Commander,
           $b: Command_UAV_Return      FROM UAV_Operator
    DO ADD $a PRECEDES $b; OD;


ROOT Control_Station: Receive_Video
                      (* Receive_Video *);

/***INTERACTIONS***/

Control_Station, Mission_Commander SHARE ALL Receive_Video;

/*-----------------------------
  Air Vehicle BEHAVIORS
-------------------------------*/
ROOT Air_Vehicle: Start_GPS_Navigation
                  Transit_to_Mission_Location
                  Detect_Beacon
                  Start_Searching
                  
                  Transmit_Video

                  (*	Vessel_Not_Found
                    	Continue_Searching
                    	Transmit_Video		*)
 
/* These probabilities are estimates
   If possible, these should be adjusted based on operational experience
*/
                  ( <<0.90>> Locate_Vessel
                             Holds_over_Vessel
                             Receive_Command
                             Drop_Payload
/* These probabilities are estimates
   If possible, these should be adjusted based on operational experience
*/
                      
                             ( <<0.90>> Payload_on_Target 		|
                               <<0.10>> Payload_Misses_Target 	)
                      
                    	| <<0.08>> Vessel_Not_Found 
                      			   Stop_Search
                    	| <<0.02>> Bingo_Fuel 
                  )

                  Return_to_Hold_Point
                  Shut_Down;


/***INTERACTIONS***/

COORDINATE $a: Transmit_Video	FROM Air_Vehicle,
           $b: Receive_Video	FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Locate_Vessel                FROM Air_Vehicle,
           $b: Confirm_Vessel               FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Vessel_Not_Found               FROM Air_Vehicle,
           $b: ( Confirm_Continue_Search |
                 Confirm_Not_Found )          FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Bingo_Fuel                   FROM Air_Vehicle,
           $b: Confirm_Bingo_Fuel           FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Command_UAV_To_Drop_Payload  FROM UAV_Operator,
           $b: Receive_Command              FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Command_UAV_Continue_Search  FROM UAV_Operator,
           $b: Continue_Searching           FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Release_UAV_to_Second_Location   FROM UAV_Operator,
           $b: Stop_Search                      FROM Air_Vehicle
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_on_Target            FROM Air_Vehicle,
           $b: Receive_Payload              FROM Rescuee
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: Payload_on_Target            FROM Air_Vehicle,
           $b: Confirms_Drop_via_Video_Feed FROM Mission_Commander
    DO ADD $a PRECEDES $b; OD;

COORDINATE $a: ( Stop_Search |
                 Payload_Misses_Target | Bingo_Fuel)    FROM Air_Vehicle,
           $b: Payload_Not_Received         			FROM Rescuee
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

/*-----------------------------
  Launch and Recovery System BEHAVIORS
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

IF #Bingo_Fuel > 0 THEN MARK;FI;
