/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 08. Model of Employee Employer             │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the modeling of a business process  │ │
│*│ │ in MP.                                             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The site http://www.infoq.com/articles/bpelbpm     │ │
│*│ │ "Why BPEL is not the holy grail for BPM" provides  │ │
│*│ │ an example of a process that can be described in   │ │
│*│ │ BPMN but not in BPEL. It is claimed to be a        │ │
│*│ │ challenge for process specification.               │ │
│*│ │                                                    │ │
│*│ │ Here is the description.                           │ │
│*│ │ "When a new employee arrives at a company, a       │ │
│*│ │ workflow is instantiated. First a record needs to  │ │
│*│ │ be created in the Human Resources database.        │ │
│*│ │ Simultaneously, an office has to be provided. As   │ │
│*│ │ soon as the Human Resources activity has been      │ │
│*│ │ completed, the employee can undergo a medical      │ │
│*│ │ check. During that time, a computer is provided.   │ │
│*│ │ This is only possible when both an office has been │ │
│*│ │ set up and an account created in the information   │ │
│*│ │ system from the human resource database. When both │ │
│*│ │ the computer and the medical check have been       │ │
│*│ │ performed, the employee is ready to work. Of       │ │
│*│ │ course, you may want to model this simple process  │ │
│*│ │ differently, but the point here is that you cannot │ │
│*│ │ define a structured parallel workflow [in BPEL]    │ │
│*│ │ that is equivalent to this one ..."                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 13: Business process model" from          │ │
│*│ │    Auguston, M. "Monterey Phoenix System and       │ │
│*│ │    Software Architecture and Workflow Modeling     │ │
│*│ │    Language Manual" (Version 4). 2020. Available   │ │
│*│ │    online:                                         │ │
│*│ │    https://wiki.nps.edu/display/MP/Documentation   │ │
│*│ │                                                    │ │
│*│ │ Vigneras, Pierre. "Why BPEL is not the holy grail  │ │
│*│ │    for BPM." InfoQ. October 21, 2008.              │ │
│*│ │    https://www.infoq.com/articles/bpelbpm/         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, business process;                        │ │
│*│ │ coordination, across hierarchy levels              │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1. Trace viewing includes a "Swim    │ │
│*│ │ Lanes" option but the inclusion and precedence     │ │
│*│ │ relations may best be viewed by sliding both root  │ │
│*│ │ event boxes to the left so that the inclusion      │ │
│*│ │ arrows become visible.                             │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
