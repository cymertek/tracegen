/* Example9_Employee_Employer.mp

The web site http://www.infoq.com/articles/bpelbpm 
“Why BPEL is not the holy grail for BPM “ 
provides an example of a process that can be described 
in BPMN but not in BPEL. 
It is claimed to be a challenge for process specification.

Here is the description. 
“When a new employee arrives at a company, a workflow is instantiated. 
First a record needs to be created in the Human Resources database. 
Simultaneously, an office has to be provided. 
As soon as the Human Resources activity has been completed, 
the employee can undergo a medical check. During that time, 
a computer is provided. This is only possible when both an office 
has been set up and an account created in the information system 
from the human resource database. When both the computer and the 
medical check have been performed, the employee is ready to work. 
Of course, you may want to model this simple process differently, 
but the point here is that you cannot define a structured 
parallel workflow [in BPEL] that is equivalent to this one ..." 
	
	Run for scope 1. The "Sequence" or "Swim Lanes" 
	layouts are the most appropriate for browsing traces here.
	Some box reshuffling may be needed to improve the trace layout. 
*/

SCHEMA Employee_Employer

ROOT Employee: 	SendArrivalDate
				MedicalCheck
				ReadyToWork;
				
ROOT Employer: 	EmployeeArrival  
	/* these are concurrent threads */
			{  Fill_HR_DB   	MedicalCheck,
		   	   ProvideOffice   	ProvideComputer }
			ReadyToWork;

Employee, Employer SHARE ALL MedicalCheck, ReadyToWork;

/* coordination of two events in different threads */
COORDINATE	$a: SendArrivalDate 	FROM Employee, 
		    $b: EmployeeArrival 	FROM Employer
	DO 	ADD $a PRECEDES $b; OD;

/* coordination between two events deep inside the process */
COORDINATE 	$a: Fill_HR_DB   	FROM Employer, 
		    $b: ProvideComputer FROM Employer
	DO 	ADD $a PRECEDES $b; 	OD;
