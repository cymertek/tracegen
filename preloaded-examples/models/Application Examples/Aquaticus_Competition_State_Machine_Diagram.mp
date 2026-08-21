/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Aquaticus Competition State Machine Diagram │
│*│ │  Created by Tyler Errico in July, 2022.            │ │
│*│ │  Edited by Pamela Dyer in December, 2022.          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the construction of a state machine │ │
│*│ │ diagram for one of the human-robot teams in the    │ │
│*│ │ "capture-the-flag"-inspired Aquaticus competition. │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This MP model shows all detailed steps that the    │ │
│*│ │ "Red Team" could follow in a real Aquaticus game.  │ │
│*│ │ It captures the full exercise, starting with the   │ │
│*│ │ robots powering on, to then executing the mission  │ │
│*│ │ (game) with optional pause and reset sequences, to │ │
│*│ │ finishing with the robots powering off.            │ │
│*│ │ Trace 1 at Scope 1 is the baseline case narrative  │ │
│*│ │ from this model: the Red Team robots power on,     │ │
│*│ │ receive approval for the mission, initialize, then │ │
│*│ │ execute the mission, receive the signal to dock    │ │
│*│ │ once the mission is complete, then dock, and       │ │
│*│ │ finally power off.                                 │ │
│*│ │ Traces 2 through 6 at Scope 1 show alternative     │ │
│*│ │ case narratives, and traces at Scopes 2 and 3      │ │
│*│ │ represent event flows for additional iterations.   │ │
│*│ │ The names of all "State" events were capitalized,  │ │
│*│ │ and the names of "Transition" events were given    │ │
│*│ │ all lowercase letters. This was to make it very    │ │
│*│ │ clear that events in this model always alternate   │ │
│*│ │ between States and Transitions, with no exceptions.│ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ T. Errico, "Human-Robot Teaming: State Machine,"   │ │
│*│ │ MPVIP Cohort 4 Showcase Presentation, United States│ │
│*│ │ Military Academy Robotics Research Center,         │ │
│*│ │ West Point, NY, USA, Summer 2022.                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, aquaticus competition;                   │ │
│*│ │ graph, finite state transition diagram             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3. In the diagram, the    │ │
│*│ │ "States" can be dragged around so all events can   │ │
│*│ │ be viewed in the desired way.                      │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 6 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 39 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 340 traces in approx. 3.8 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/


SCHEMA RED_TEAM_STATE_MACHINE_DIAGRAM

ROOT RED_TEAM:
/*RED_TEAM power on sequence*/
START
start_process
RED_TEAM_POWER_OFF
red_team_initiate_power_on_sequence
RED_TEAM_POWERING_ON
red_team_power_on_complete
RED_TEAM_POWER_ON
/*RED_TEAM_initialization_sequence*/
red_team_receive_shoreside_approval
RED_TEAM_INITIALIZING
red_team_initialized
/*RED_TEAM start ex sequence*/
RED_TEAM_STANDING_BY
red_team_receive_start_ex_signal
/*RED_TEAM gameplay loop would go here*/
RED_TEAM_EXECUTING_MISSION
/*RED_TEAM gameplay interruption loop*/
(*
	red_team_receive_pause_ex_signal
	RED_TEAM_PAUSE_EX
	red_team_hold_position
	RED_TEAM_HOLDING_POSITION
	red_team_receive_resume_ex_signal 
	RED_TEAM_EXECUTING_MISSION
*)
/*RED_TEAM end ex sequence*/
red_team_receive_end_ex_signal
RED_TEAM_END_EX
red_team_hold_position
RED_TEAM_AWAITING_COMMAND
/*RED_TEAM reset sequence*/
(*
	red_team_receive_reset_signal 
    RED_TEAM_RESET 
    red_team_complete_reset 
	RED_TEAM_STANDING_BY
    red_team_receive_start_ex_signal
	/*RED_TEAM gameplay loop would go here*/
	RED_TEAM_EXECUTING_MISSION
	/*RED_TEAM gameplay interruption loop*/
	(*
		red_team_receive_pause_ex_signal
		RED_TEAM_PAUSE_EX
		red_team_hold_position
		RED_TEAM_HOLDING_POSITION
		red_team_receive_resume_ex_signal 
		RED_TEAM_EXECUTING_MISSION
	*)
	/*RED_TEAM end ex sequence*/
	red_team_receive_end_ex_signal
	RED_TEAM_END_EX
	red_team_hold_position
	RED_TEAM_AWAITING_COMMAND
*)
/*RED_TEAM docking sequence*/
red_team_receive_dock_signal
RED_TEAM_DOCKING
red_team_complete_dock
RED_TEAM_DOCK_COMPLETE
/*RED_TEAM shutdown sequence*/
red_team_initiate_power_off_sequence
RED_TEAM_SHUTTING_DOWN
red_team_shutdown_complete
RED_TEAM_POWER_OFF
end_process
END
;

/* 	Create a diagnostic table on each event trace showing 
	the state-transition-state triples used to graph the 
    state diagram */
/*
TABLE StatechartDiagnosticTable 
		{	TITLE ("Statechart Triples from This Trace");
    		TABS 	string state1,
					string transition,
					string state2;	
		};

/*	The following command empties the table before
	populating it for each trace */
/*CLEAR StatechartDiagnosticTable;*/

GRAPH RED_TEAM_StateDiagram{ TITLE("Red_Team_State_Diagram"); };

COORDINATE 
	<CUT_END>   $state1: /* these are RED_TEAM states */
					( START | RED_TEAM_POWER_OFF | RED_TEAM_POWERING_ON | RED_TEAM_POWER_ON 
                        | RED_TEAM_INITIALIZING | RED_TEAM_STANDING_BY | RED_TEAM_EXECUTING_MISSION 
                        | RED_TEAM_PAUSE_EX | RED_TEAM_HOLDING_POSITION 
                        | RED_TEAM_EXECUTING_MISSION | RED_TEAM_END_EX 
                        | RED_TEAM_AWAITING_COMMAND | RED_TEAM_RESET 
                        | RED_TEAM_STANDING_BY | RED_TEAM_DOCKING 
                        | RED_TEAM_DOCK_COMPLETE | RED_TEAM_SHUTTING_DOWN 
                        | RED_TEAM_POWER_OFF | END),

			 	$transition: /* these are RED_TEAM state transitions*/
     				( start_process | red_team_initiate_power_on_sequence | red_team_power_on_complete
                        | red_team_receive_shoreside_approval | red_team_initialized 
                        | red_team_receive_start_ex_signal 
                        | red_team_receive_pause_ex_signal | red_team_hold_position 
                        | red_team_receive_resume_ex_signal
                        | red_team_receive_end_ex_signal | red_team_hold_position 
                        | red_team_receive_reset_signal | red_team_complete_reset 
                        | red_team_receive_dock_signal | red_team_complete_dock
                        | red_team_initiate_power_off_sequence 
                        | red_team_shutdown_complete | end_process),

	<CUT_FRONT> $state2:  /* these are RED_TEAM states */ 
				 	( START | RED_TEAM_POWER_OFF | RED_TEAM_POWERING_ON | RED_TEAM_POWER_ON 
                        | RED_TEAM_INITIALIZING | RED_TEAM_STANDING_BY | RED_TEAM_EXECUTING_MISSION 
                        | RED_TEAM_PAUSE_EX | RED_TEAM_HOLDING_POSITION 
                        | RED_TEAM_EXECUTING_MISSION | RED_TEAM_END_EX 
                        | RED_TEAM_AWAITING_COMMAND | RED_TEAM_RESET 
                        | RED_TEAM_STANDING_BY | RED_TEAM_DOCKING 
                        | RED_TEAM_DOCK_COMPLETE | RED_TEAM_SHUTTING_DOWN 
                        | RED_TEAM_POWER_OFF | END )

	 DO	WITHIN RED_TEAM_StateDiagram { ADD 	LAST ($state1) 
        							ARROW($transition) 
        							LAST ($state2); 
							 };
	OD;
	/* 	Populate the diagnostic table with each state1-transition-state2 
    	triple */ 
	/*StatechartDiagnosticTable <|
							state1: SAY($state1),
							transition: SAY($transition),
							state2: SAY($state2) ;
	 OD;

SHOW StatechartDiagnosticTable;*/

/* Plot the charts */
GLOBAL

SHOW RED_TEAM_StateDiagram;
