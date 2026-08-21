/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 17. Model of Shared Menu Selections        │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To obtain the probability of each valid trace.     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ This is a behavior model of two friends out to     │ │
│*│ │ lunch. Menu options include a large salad, a half  │ │
│*│ │ salad, and a half sandwich. I only want a salad,   │ │
│*│ │ but my friend is deciding between a salad and a    │ │
│*│ │ half sandwich. For the purpose of this example, I  │ │
│*│ │ am inclined to share a large salad for the cost    │ │
│*│ │ saving, and my friend usually prefers salad as     │ │
│*│ │ well but sometimes likes a sandwich. This model    │ │
│*│ │ obtains the probability that these friends share a │ │
│*│ │ large salad or order smaller meals separately.     │ │
│*│ │                                                    │ │
│*│ │ Type 1 probability is used here because the events │ │
│*│ │ in this model have probabilities that don't depend │ │
│*│ │ on other events it is related to by precedence or  │ │
│*│ │ inclusion. The product of probabilities assigned   │ │
│*│ │ to events in each unconstrained trace segment is   │ │
│*│ │ obtained, then the probabilities of traces cut     │ │
│*│ │ from the model by constraint(s) are discarded. The │ │
│*│ │ probabilities of the remaining (valid) traces are  │ │
│*│ │ then normalized to sum up to 1. The normalization  │ │
│*│ │ is done by summing the probabilities of only the   │ │
│*│ │ valid traces and then dividing each valid trace's  │ │
│*│ │ probability by that sum. This prorating operation  │ │
│*│ │ distributes the contributions that would have been │ │
│*│ │ made by the rejected traces equally across the     │ │
│*│ │ valid traces. The resulting probabilities show how │ │
│*│ │ "SHARE ALL" increases the chances of the shared    │ │
│*│ │ event.                                             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 31: Shared events with probabilities"     │ │
│*│ │ from Auguston, M. "Monterey Phoenix System and     │ │
│*│ │ Software Architecture and Workflow Modeling        │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, menu item selections; event sharing;     │ │
│*│ │ probability, Type 1                                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Menu_Selections

ROOT Me: ( <<0.6>> Order_Large_Salad | Order_Half_Salad );

ROOT My_Friend: (<<0.8>> Order_Large_Salad | Order_Half_Sandwich );

Me, My_Friend SHARE ALL Order_Large_Salad;
