/* Example2_DataAsEvents.mp
	data items as behaviors

MP employs the Abstract Data Type (ADT) principle introduced by 
Barbara Liskov to represent data items as operations
being performed on those items.

In this model all writing in the File should be accomplished before reading.
File should not be empty. These constraints on behavior are 
captured by File root event grammar rule.
	
On the other hand, Writer’s behavior allows scenarios that skip writing at all.
Such behaviors are not compatible with File behavior patterns.

The SHARE ALL composition ensures that the schema admits 
only event traces where corresponding event sharing is implemented.

Event traces specified by the schema represent system’s emergent behavior, 
where behaviors of subsystems are influenced by the coordination.
This is a toy example of System_of_Systems emerging behavior modeling. 

Run for scopes 1 and up. The "Sequence" or "Swim Lanes" layouts are 
the most appropriate for browsing traces here. 

*/

SCHEMA Data_flow

ROOT Writer: (* ( working | writing ) *);

/* writing events should precede reading */
ROOT File:   (+ writing +) (* reading *);

Writer, File SHARE ALL writing;
	

ROOT Reader: (* ( reading | working ) *);

Reader, File SHARE ALL reading;
