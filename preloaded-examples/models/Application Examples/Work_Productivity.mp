/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Work Productivity                         │ │
│*│ │  Created by Mikhail Auguston in 2018.              │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate how to print all events present in  │ │
│*│ │ the trace with timing attributes.                  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This model demonstrates using MP to show how       │ │
│*│ │ visitors can distract workers with stacked time    │ │
│*│ │ usage. Users may reference this model when         │ │
│*│ │ learning about BUILD, COORDINATE, and SAY          │ │
│*│ │ statements in order to constrain models and        │ │
│*│ │ comment on models directly in the traces.          │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 23: Timing attribute use." from           │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, work productivity;                       │ │
│*│ │ behavior, distraction; event attribute, timing;    │ │
│*│ │ event attribute, interval; BUILD block             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 12 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 84 traces in less than 1 sec.             │ │
│*│ │ Scope 4: 780 traces in approx. 1.5 sec.            │ │
│*│ │ Scope 5: 9330 traces in approx. 1.0 min.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Work_Productivity

Work:
BUILD{
    SET duration AT LEAST 1;
    /* The new default value for the Work event duration 
		attribute is set as an interval [1..1] */
};


Visitor:
	/* set new default duration for Visitor */
BUILD{ SET duration AT LEAST [2..3]; };

Get_distracted:    (+ Visitor +) ;

ROOT Worker: (+ ( Work | Get_distracted) +);

ATTRIBUTES{ interval total_delay; };
/* delay is THIS.delay, or attribute of the whole schema event,
  and  is used to hold specific data extracted from the trace */

COORDINATE $distraction: Get_distracted
    DO total_delay +:= $distraction.duration; OD;

/* show all events present in the trace with timing attributes, 
  preserving the order of derivation, top-down, left-to-right */
COORDINATE $x: $$EVENT 
	DO SAY("   " $x 	" start " $x.start 
						" duration " $x.duration 
						" end " $x.end); 
	OD;

SAY("  Delay created by " #Visitor " visitors is " total_delay);
