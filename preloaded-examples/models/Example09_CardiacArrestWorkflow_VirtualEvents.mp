/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 09. Model of Cardiac Arrest Workflow       │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the modeling of a workflow in MP.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ When handling a cardiac arrest, the                │ │
│*│ │ check_breathing and check_pulse tasks run in       │ │
│*│ │ parallel. Once the first of these has completed,   │ │
│*│ │ the triage task is commenced. Completion of the    │ │
│*│ │ other task is ignored and does not result in a     │ │
│*│ │ second instance of the triage task. The referenced │ │
│*│ │ workflowpatterns.com websites contain a collection │ │
│*│ │ of workflow patterns specified with Petri nets.    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 9: Workflow pattern" and "Example 14:     │ │
│*│ │    Workflow pattern" from Auguston, M. "Monterey   │ │
│*│ │    Phoenix System and Software Architecture and    │ │
│*│ │    Workflow Modeling Language Manual" (Version 4). │ │
│*│ │    2020. Available online:                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ "Control-Flow Patterns." Workflow Patterns, 2011.  │ │
│*│ │    http://workflowpatterns.com/patterns/control/index.php
│*│ │                                                    │ │
│*│ │ "Pattern 9 (Structured Discriminator)." Workflow   │ │
│*│ │    Patterns, 2011.                                 │ │
│*│ │    http://workflowpatterns.com/patterns/control/advanced_branching/wcp9.php
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, triage; behavior, workflow               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Cardiac_Arrest_Workflow

ROOT Phase1: {  check_breathing [finish_first], 
                check_pulse 	[finish_first]   }

BUILD{ ENSURE #finish_first == 1; };

ROOT Triage:    identify_the_patient
                record_assessment_findings
                identify_the_priority;

COORDINATE $a: finish_first, $b: identify_the_patient
    DO ADD $a PRECEDES $b; OD;
