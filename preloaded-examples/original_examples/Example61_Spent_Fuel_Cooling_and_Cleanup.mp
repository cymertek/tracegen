/* Cooling Pool

created by K.Giammarco 5/4/2020
modified by K.Giammarco 5/8/2020 with D.VanBossuyt
modified by K.Giammarco 5/13/2020 with D.VanBossuyt

The purpose of this model is to identify the components of and 
interactions among a spent nuclear fuel cooling pool and its environment.

*/


/*—————————————————————————————
 	 		  Actors
———————————————————————————————*/
SCHEMA Spent_Fuel_Cooling_and_Cleanup_System


ROOT External_Systems: { Operator, Ext_Cooling_Loop };
    
    
    Operator: Monitor_Spent_Fuel_Pool;
		
		Monitor_Spent_Fuel_Pool:	[ Receive_Low_Water_Alert ]
            						[ Receive_Critically_Low_Water_Alarm ]
            						[ Receive_High_Temperature_Alarm ]
            						;


    Ext_Cooling_Loop: 	Supply_Cold_Water
						Remove_Warm_Water;


ROOT Heat_Exchanger: Remove_Decay_Heat;


ROOT Cooling_Loop: 	Pump_Pool_Water_into_Cooling_Loop
					Deliver_Pool_Water_to_Heat_Exchanger
					Return_Pool_Water_to_Cooling_Pool;


ROOT Spent_Fuel_Pool: 	Store_Spent_Fuel_Rods 
						{ 	Circulate_Water_for_Cooling,
                            Circulate_Water_for_Cleanup,
							Monitor_Pool_Water
						};

	Circulate_Water_for_Cooling:	Provide_Heated_Water_for_Cooling
    								Accept_Cooled_Pool_Water;

	Circulate_Water_for_Cleanup:	Provide_Radioactive_Water_for_Cleanup
									Accept_Cleaned_Pool_Water;

	Monitor_Pool_Water:	(	Water_Level_Normal 						|
        
        					Water_Level_Low
        					Notify_Operator_Low_Water
        					Accept_Low_Volume_Makeup_Water			
        
                            [	Water_Level_Critically_Low
        						Notify_Operator_Critically_Low_Water
       	 						Accept_High_Volume_Makeup_Water ]	)
							
						(	Temperature_Normal 			| 
        						Temperature_High
        						Notify_Operator_High_Temperature	) 
						;


ROOT Purification_Subsystem:	{ Purification_Loop, Water_Make_Up_System };

	Purification_Loop: 	Pump_Pool_Water_into_Purification_Subsystem
						Filter_Pool_Water
						Demineralize_Pool_Water
						Return_Pool_Water;

	Water_Make_Up_System:	[ Add_Water ];



ROOT Emergency_Water_Tank:	[ Add_Water ];


/*—————————————————————————————
 		        Interactions
———————————————————————————————*/

COORDINATE 	$a: Store_Spent_Fuel_Rods  			FROM Spent_Fuel_Pool,
			$b: Circulate_Water_for_Cooling  	FROM Spent_Fuel_Pool,
			$c: Circulate_Water_for_Cleanup		FROM Spent_Fuel_Pool,
			$d: Monitor_Pool_Water				FROM Spent_Fuel_Pool

	DO 	ADD $a radioactive_particles $b;
	 	ADD $a thermal_energy $b;
		ADD $a radioactive_particles $c;
	 	ADD $a thermal_energy $c;
		ADD $a radioactive_particles $d;
	 	ADD $a thermal_energy $d;
OD;


COORDINATE 	$a: Provide_Heated_Water_for_Cooling 		FROM Spent_Fuel_Pool,
			$b: Pump_Pool_Water_into_Cooling_Loop  		FROM Cooling_Loop
	DO 	ADD $a PRECEDES $b; 
		ADD $a hot_radioactive_pool_water $b;
	OD;


COORDINATE 	$a: Deliver_Pool_Water_to_Heat_Exchanger  	FROM Cooling_Loop,
			$b: Remove_Decay_Heat  		FROM Heat_Exchanger
	DO 	ADD $a PRECEDES $b; 
	 	ADD $a hot_radioactive_pool_water $b;
	OD;


COORDINATE 	$a: Supply_Cold_Water  	FROM External_Systems,
			$b: Remove_Decay_Heat  	FROM Heat_Exchanger,
			$c: Remove_Warm_Water	FROM External_Systems
	DO 	ADD $a PRECEDES $b;
		ADD $b PRECEDES $c;
	 	ADD $a cold_water $b;
	 	ADD $b hot_water $c;
OD;



COORDINATE 	$a: Provide_Radioactive_Water_for_Cleanup  	FROM Spent_Fuel_Pool,
			$b: Pump_Pool_Water_into_Purification_Subsystem  	FROM Purification_Subsystem
	DO 	ADD $a PRECEDES $b; 
	 	ADD $a hot_radioactive_pool_water $b;
OD;



COORDINATE 	$a: Remove_Decay_Heat  							FROM Heat_Exchanger,
			$b: Return_Pool_Water_to_Cooling_Pool  			FROM Cooling_Loop
	DO 	ADD $a PRECEDES $b; 
	 	ADD $a cooled_radioactive_pool_water $b;
OD;


COORDINATE 	$a: Return_Pool_Water_to_Cooling_Pool  	FROM Cooling_Loop,
			$b: Accept_Cooled_Pool_Water 			FROM Spent_Fuel_Pool
	DO 	ADD $a PRECEDES $b;
        ADD $a cooled_radioactive_pool_water $b;
	OD;	


COORDINATE 	$a: Return_Pool_Water  			FROM Purification_Subsystem,
			$b: Accept_Cleaned_Pool_Water 	FROM Spent_Fuel_Pool
	DO 	ADD $a PRECEDES $b;
        ADD $a hot_cleaned_pool_water $b;
	OD;	


/* If Water Level Low */

COORDINATE 	$a: Water_Level_Low  			FROM Spent_Fuel_Pool,
			$b: Add_Water					FROM Purification_Subsystem
	DO 	ADD $a PRECEDES $b;
        ADD $a set_point_1_trigger $b;

	OD;	
		
COORDINATE 	$a: Notify_Operator_Low_Water	FROM Spent_Fuel_Pool,
			$b: Receive_Low_Water_Alert				FROM External_Systems
	DO 	ADD $a PRECEDES $b;
        ADD $a set_point_1_alert $b;
	OD;	


COORDINATE 	$a: Water_Level_Critically_Low 		FROM Spent_Fuel_Pool,
			$b: Add_Water						FROM Emergency_Water_Tank
	DO 	ADD $a PRECEDES $b;
        ADD $a set_point_2_trigger $b;
	OD;	

COORDINATE 	$a: Notify_Operator_Critically_Low_Water 	FROM Spent_Fuel_Pool,
			$b: Receive_Critically_Low_Water_Alarm			FROM External_Systems
	DO 	ADD $a PRECEDES $b;
        ADD $a set_point_2_alarm $b;
	OD;	


COORDINATE 	$a: Add_Water							FROM Purification_Subsystem,
			$b: Accept_Low_Volume_Makeup_Water		FROM Spent_Fuel_Pool
	DO 	ADD $a PRECEDES $b;
        ADD $a clean_cool_water $b;
	OD;	


COORDINATE 	$a: Add_Water							FROM Emergency_Water_Tank,
			$b: Accept_High_Volume_Makeup_Water		FROM Spent_Fuel_Pool
	DO 	ADD $a PRECEDES $b;
        ADD $a clean_cool_water $b;
	OD;	


COORDINATE 	$a: Notify_Operator_High_Temperature 	FROM Spent_Fuel_Pool,
			$b: Receive_High_Temperature_Alarm			FROM External_Systems
	DO 	ADD $a PRECEDES $b;
        ADD $a high_temp_alarm $b;
	OD;	   					
