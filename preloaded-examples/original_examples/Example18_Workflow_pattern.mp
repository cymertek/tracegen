/* Example18 Workflow pattern

the web site
http://workflowpatterns.com/patterns/control/index.php
contains a collection of workflow patterns specified with Petri nets.

Pattern 9 (Structured Discriminator)
http://workflowpatterns.com/patterns/control/advanced_branching/wcp9.php

When handling a cardiac arrest, the check_breathing and check_pulse tasks 
run in parallel. Once the first of these has completed, the triage task 
is commenced. Completion of the other task is ignored and does not result 
in a second instance of the triage task.

run for scope 1
*/

SCHEMA Cardiac_Arrest

ROOT Phase1: {  check_breathing [finish_first], 
                check_pulse 	[finish_first]   }

BUILD{ ENSURE #finish_first == 1; };

ROOT Triage:    identify_the_patient
                record_assessment_findings
                identify_the_priority;

COORDINATE $a: finish_first, $b: identify_the_patient
    DO ADD $a PRECEDES $b; OD;
