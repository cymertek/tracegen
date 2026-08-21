/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Aquaticus Competition Search and Rescue   │ │
│*│ │  Created by Luke Mattson, Vishal Patel, and        │ │
│*│ │     Michael Sagos in July, 2022.                   │ │
│*│ │  Modified (Risk Analysis code added) by Alexander  │ │
│*│ │     Nguyen in November, 2022.                      │ │
│*│ │  Edited by Pamela Dyer in December, 2022.          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate a Search and Rescue operation and   │ │
│*│ │ a risk analysis for the human-robot teams in the   │ │
│*│ │ "capture-the-flag"-inspired Aquaticus competition. │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ In this MP model of the Aquaticus game, there are  │ │
│*│ │ 5 roots: Red Team, Blue Team, the Environment (the │ │
│*│ │ weather), Shoreside (in charge of managing the     │ │
│*│ │ game), and SAR (the Search and Rescue team that    │ │
│*│ │ responds to emergencies). There are instructions   │ │
│*│ │ below for commenting out specific constraints that │ │
│*│ │ will show emergent behaviors of interest, all of   │ │
│*│ │ which were discovered while this model was being   │ │
│*│ │ built. Afterwards, a risk analysis was added to    │ │
│*│ │ this model (the assigning of the risk attributes   │ │
│*│ │ can be found below on Lines 283-321).              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ L. Mattson, V. Patel, and M. Sagos, "Human-Robot   │ │
│*│ │ Teaming: SAR Expansion," MPVIP Cohort 4 Showcase   │ │
│*│ │ Presentation, United States Military Academy Robotics│
│*│ │ Research Center, West Point, NY, USA, Summer 2022. │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, aquaticus competition; SAY statement;    │ │
│*│ │ event attribute, number; coordination, event;      │ │
│*│ │ risk score; analysis, risk; report, global; table; │ │
│*│ │ probability, Type 1; behavior, SAR; capture the flag │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 8 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA Aquaticus_Search_and_Rescue_with_Risk_Analysis

/* Setting up all of the events */


ROOT RedTeam: await_shoreside_approval 
(shoreside_approves_red red_team_initiate
    | shoreside_postpones_red standby_red);

red_team_initiate: (man_overboard_r |
/* normal CTF logic */
(keep_playing_r  | all_stop_r)



);

keep_playing_r: (robot_in_danger_r |
/* normal CTF logic */
(continue_playing_r | all_stop_r2 )


);


ROOT BlueTeam: await_shoreside_approval 
(shoreside_approves_blue blue_team_initiate
    | shoreside_postpones_blue standby_blue);

blue_team_initiate: (man_overboard_b |
/* normal CTF logic */
(keep_playing_b | all_stop_b )
 
);

keep_playing_b: (robot_in_danger_b  |
/* normal CTF logic */
(continue_playing_b | all_stop_b2 )


);


ROOT Environment: weather_status;
weather_status: (safe_weather | unsafe_weather);


ROOT Shoreside: acquire_basic_data_on_participants initialize_moosdb analyze_weather;

analyze_weather: (
    weather_unsafe postpone_exercise | weather_safe approve_exercise playing_game
);

playing_game: ( stop_game| all_ok 
    (stop_game2| all_ok2)

);

stop_game: record_emergency_in_MOOSDB send_appropriate_info signal_SAR;
stop_game2: record_emergency_in_MOOSDB send_appropriate_info signal_SAR;


ROOT SAR: search_and_rescue_team_initiate
		  prepare_for_emergency_situation
		  standby_for_rescue_signal
          
; 

standby_for_rescue_signal: (await_order | SAR_signal_received deploy_to_estimated_location);


ENSURE #man_overboard_r + #man_overboard_b > 0 <-> #stop_game == 1;

ENSURE ( ( #keep_playing_r + #keep_playing_b == 2 )
           OR ( #standby_red + #standby_blue == 2 ) )
               <-> #stop_game == 0;

ENSURE #robot_in_danger_r + #robot_in_danger_b > 0 <-> #stop_game2 == 1;

ENSURE #continue_playing_r == 1 -> #all_stop_b2 == 0;

ENSURE #continue_playing_b == 1 -> #all_stop_r2 == 0;

ENSURE #all_stop_r2 == 1 -> #all_stop_b2 == 0;

/* Setting the game up */

/*
   Commenting out Lines 165-175 causes Emergent Behavior #1 (Trace 3).
   The example story is: The weather is unsafe but Shoreside believes
   it is safe, so the game is approved to begin. While it is being played,
   suddenly a player on the Red Team crashes into a player on the Blue Team,
   resulting in two man overboard events. SAR is then signaled but
   the method of communication fails and SAR does not receive the signal
   at all. SAR remains in the position where it is awaiting an order,
   unaware that the signal was sent.

   Commenting out Lines 165-195 causes Emergent Behavior #2 (Trace 30).
   The example story is: The weather is safe but a possible insider threat
   occurs, with Shoreside being told the weather is unsafe and the game
   should be postponed. Even though the game is not played, SAR is deployed
   due to an "emergency" signal from this insider threat, whose goal
   is to disrupt game play and consume resources.

   Commenting out Lines 197-222 causes Emergent Behavior #3 (Trace 2).
   The example story is: there is a man overboard on one team (here
   the red) but the opposing team continues playing (here the blue),
   because they are too focused on the game and unaware that the
   red team has an emergency situation and SAR is being deployed.
*/


COORDINATE $x: signal_SAR FROM Shoreside,
		   $y: SAR_signal_received FROM SAR
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: safe_weather FROM Environment,
		   $y: weather_safe FROM Shoreside
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: unsafe_weather FROM Environment,
		   $y: weather_unsafe FROM Shoreside
	DO ADD $x PRECEDES $y; OD;

/* Beginning the game */


COORDINATE $x: approve_exercise FROM Shoreside,
		   $y: shoreside_approves_red FROM RedTeam
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: approve_exercise FROM Shoreside,
		   $y: shoreside_approves_blue FROM BlueTeam
	DO ADD $x PRECEDES $y; OD;


COORDINATE $x: postpone_exercise FROM Shoreside,
		   $y: shoreside_postpones_red FROM RedTeam
	DO ADD $x PRECEDES $y; OD;

COORDINATE $x: postpone_exercise FROM Shoreside,
		   $y: shoreside_postpones_blue FROM BlueTeam
	DO ADD $x PRECEDES $y; OD;

IF #man_overboard_r == 1 AND #man_overboard_b == 0 THEN 
    COORDINATE $x: man_overboard_r,
               $y: stop_game,
				$z: all_stop_b
			
        DO ADD $x PRECEDES $y,
				$x PRECEDES $z; OD;
FI;

IF #man_overboard_r == 0 AND #man_overboard_b == 1 THEN
    COORDINATE $x: man_overboard_b,
               $y: stop_game,
				$z: all_stop_r
        DO ADD $x PRECEDES $y,
				$x PRECEDES $z;
		OD;
FI;

IF #man_overboard_r == 1 AND #man_overboard_b == 1 THEN
    COORDINATE $x: man_overboard_r,
               $y: man_overboard_b,
               $z: stop_game
        DO ADD     $x PRECEDES $z,
                   $y PRECEDES $z;
        OD;
FI;

IF #keep_playing_r == 1 AND #keep_playing_b == 1 THEN
    COORDINATE $x: keep_playing_r,
               $y: keep_playing_b,
               $z: all_ok
        DO ADD     $x PRECEDES $z,
                   $y PRECEDES $z;
        OD;
FI;



 /*sinking boat */

IF #robot_in_danger_r == 1 AND #robot_in_danger_b == 0 THEN 
    COORDINATE $x: robot_in_danger_r,
               $y: stop_game2,
				$z: all_stop_b2
			
        DO ADD $x PRECEDES $y,
				$x PRECEDES $z; OD;
FI;

IF #robot_in_danger_r == 0 AND #robot_in_danger_b == 1 THEN
    COORDINATE $x: robot_in_danger_b,
               $y: stop_game2,
				$z: all_stop_r2
        DO ADD $x PRECEDES $y,
				$x PRECEDES $z;
		OD;
FI;

IF #robot_in_danger_r == 1 AND #robot_in_danger_b == 1 THEN
    COORDINATE $x: robot_in_danger_r,
               $y: robot_in_danger_b,
               $z: stop_game2
        DO ADD     $x PRECEDES $z,
                   $y PRECEDES $z;
        OD;
FI; 


IF #continue_playing_r == 1 AND #continue_playing_b == 1 THEN
    COORDINATE $x: continue_playing_r,
               $y: continue_playing_b,
               $z: all_ok2
        DO ADD     $x PRECEDES $z,
                   $y PRECEDES $z;
        OD;
FI;



ATTRIBUTES	{	number 	likelihood, impact, trace_risk_score, 
    					sum_risk_score, max_risk_score, 
    					max_risk_trace_unique_number;	
			};

/* Assigns attributes */

COORDINATE $drones_collide: man_overboard_r
	DO 	$drones_collide.likelihood:= 0.7;
		$drones_collide.impact:= 8; 
	OD;

COORDINATE $drones_collide: man_overboard_b 
	DO 	$drones_collide.likelihood:= 0.7;
		$drones_collide.impact:= 8; 
	OD;

COORDINATE $robot_malfunction: robot_in_danger_r
	DO 	$robot_malfunction.likelihood:= 0.6;
		$robot_malfunction.impact:= 9; 
	OD;

COORDINATE $robot_malfunction: robot_in_danger_b
	DO 	$robot_malfunction.likelihood:= 0.6;
		$robot_malfunction.impact:= 9; 
	OD;

COORDINATE $environment_weather_conditions: unsafe_weather
	DO 	$environment_weather_conditions.likelihood:= 0.5;
		$environment_weather_conditions.impact:= 5; 
	OD;

COORDINATE $shoreside_weather_conditions: weather_unsafe
	DO 	$shoreside_weather_conditions.likelihood:= 0.5;
		$shoreside_weather_conditions.impact:= 5; 
	OD;

COORDINATE $shoreside_approval: continue_playing_r
	DO 	$shoreside_approval.likelihood:= 0.4;
		$shoreside_approval.impact:= 1; 
	OD;

COORDINATE $shoreside_approval: continue_playing_b
	DO 	$shoreside_approval.likelihood:= 0.4;
		$shoreside_approval.impact:= 1; 
	OD;

 


/* Trace Risk Table and Summary */

TABLE event_risks	{ 	TITLE ("Event Risks");
    					TABS 	string Event, 
								string Likelihood,
								string Impact,
    							string Risk_Score;
					};

CLEAR event_risks;

COORDINATE $e: $$EVENT
	
	DO 	trace_risk_score+:= ($e.likelihood*$e.impact);
		IF ($e.likelihood*$e.impact) > 0 THEN
				event_risks <|
					Event: SAY($e),
					Likelihood: SAY($e.likelihood),
					Impact: SAY($e.impact),
					Risk_Score: SAY($e.likelihood*$e.impact);	
		FI;
	
		/*	If the TRACE RISK SCORE for a given trace exceeds the 
        	current global maximum risk factor value (initialized 
            at zero), then make the max risk factor THIS trace's 
            risk factor and get its trace id for the max risk trace. */
		IF  trace_risk_score > GLOBAL.max_risk_score THEN 
			GLOBAL.max_risk_score:= trace_risk_score;
			GLOBAL.max_risk_trace_unique_number:= trace_id;
		FI;

			/*MARK traces that have a risk factor greater than a certain value*/

			IF trace_risk_score >= 9 THEN MARK; FI;
	OD;

/* 	If there is a risk to the trace then show the risk table on the
	trace and say the total trace risk. */
IF trace_risk_score > 0 THEN 	SHOW event_risks;
								SAY("Total Trace Risk: "trace_risk_score); 	
FI;


/**** Calculate Total Risk ****/

/* Sum up risk scores across all traces */
GLOBAL.sum_risk_score +:= trace_risk_score;
	

/* Create and display Global Risk Report */

GLOBAL

REPORT Global_Risk { TITLE ( "Risk Report for Scope " $$scope ); };

/* Include these SAY statements in the Global_Risk Report */
SAY("Total risk over " #$$TRACE " traces (sum of trace risk scores): " 
        						GLOBAL.sum_risk_score) 
								=> Global_Risk;
SAY("Highest Risk: " GLOBAL.max_risk_score" (trace " 
        						GLOBAL.max_risk_trace_unique_number")") 
								=> Global_Risk;
SAY("Average Risk: " GLOBAL.sum_risk_score/#$$TRACE) 
								=> Global_Risk;
SAY("Sort by Marked to view traces with above average risk >=9.") 
								=> Global_Risk; 

SHOW Global_Risk;
