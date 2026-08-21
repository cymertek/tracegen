/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 02. Model of Data Flow                     │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To illustrate the representation of data items as  │ │
│*│ │ behaviors.                                         │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ MP employs the Abstract Data Type (ADT) principle  │ │
│*│ │ introduced by Barbara Liskov to represent data     │ │
│*│ │ items as operations being performed on those       │ │
│*│ │ items. In this model, the Writer and the Reader    │ │
│*│ │ are components, and the File is the data item      │ │
│*│ │ shared between components.                         │ │
│*│ │                                                    │ │
│*│ │ The File root grammar rule captures the following  │ │
│*│ │ constraints on the behavior of File for this       │ │
│*│ │ model: all writing in the File should be           │ │
│*│ │ accomplished before reading, and File should not   │ │
│*│ │ be empty.                                          │ │
│*│ │                                                    │ │
│*│ │ On the other hand, Writer’s behavior allows        │ │
│*│ │ scenarios that skip writing at all. Such behaviors │ │
│*│ │ are not compatible with File behavior patterns.    │ │
│*│ │                                                    │ │
│*│ │ The SHARE ALL composition ensures that the schema  │ │
│*│ │ admits only event traces where corresponding event │ │
│*│ │ sharing is implemented.                            │ │
│*│ │                                                    │ │
│*│ │ Event traces specified by the schema represent the │ │
│*│ │ system’s emergent behavior, where behaviors of     │ │
│*│ │ subsystems are influenced by the coordination.     │ │
│*│ │ This is a toy example of System of Systems         │ │
│*│ │ emerging behavior modeling.                        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 3: Data Flow" from Auguston, M. "Monterey │ │
│*│ │ Phoenix System and Software Architecture and       │ │
│*│ │ Workflow Modeling Language Manual" (Version 4).    │ │
│*│ │ 2020.  Available online:                           │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, data flow; event sharing                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 3 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 28 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 165 traces in less than 1 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Data_Flow

ROOT Writer: (* ( working | writing ) *);

/* writing events should precede reading */
ROOT File:   (+ writing +) (* reading *);

Writer, File SHARE ALL writing;
	

ROOT Reader: (* ( reading | working ) *);

Reader, File SHARE ALL reading;
