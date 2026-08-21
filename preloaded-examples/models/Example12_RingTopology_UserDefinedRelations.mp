/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 12. Model of Ring Topology                 │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of user-defined relations.  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ The following is a model of network ring, where    │ │
│*│ │ each node interacts with its left and right        │ │
│*│ │ neighbors only.                                    │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 16: User-defined relations" from          │ │
│*│ │ Auguston, M. "Monterey Phoenix System and Software │ │
│*│ │ Architecture and Workflow Modeling Language        │ │
│*│ │ Manual" (Version 4). 2020. Available online:       │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, ring topology; event reshuffling;        │ │
│*│ │ user-defined relation; isomorphism                 │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 1 trace in less than 1 sec.               │ │
│*│ │ Scope 2: 32 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 1570 traces in approx. 31 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Ring_Topology
/* model of networking ring, where each node sends/receives
to/from its left and right neighbor.
*/

Node: (* (  send_left           | send_right            | 
            receive_from_left   | receive_from_right    )   *);

ROOT Ring: {+ Node +}

/*  The following coordinations are done over the root Ring,
    the ring may contain one or more Nodes */
BUILD{

COORDINATE              $x1: Node,/* This thread produces a default set */
<SHIFT_LEFT> $x2: Node 

/* SHIFT_LEFT reshuffling, means that when the default set 
of Node events is selected (all Node events from THIS),
it takes the first event from the
beginning and puts it to the end of sequence.
This adjusted thread is used to produce the ring topology */

DO
/*  The COORDINATE loop proceeds to set up new relations between $x1 and its neighbor */
    ADD $x1 left_neighbor_of    $x2,
        $x2 right_neighbor_of   $x1;
OD;

/*-----------------------------------------------------
We assert the single ring property.
^R yields a transitive closure of the relation R.
Ring topology means that every node can be reached from any node in both directions.
Although it is possible to prove that the previous coordination sets the ring properly,
the following assertion check is provided for clarity to demonstrate how such 
properties can be expressed in MP. 
If uncommented, it will increase the trace generation time.
Assertions are mostly used for model testing/debugging.
You can uncomment it and try to run.
--------------------------------------------------------*/

/*----------------------------------------------------
CHECK FOREACH $a: Node, $b: Node
(   $a  ^left_neighbor_of    $b     AND
    $a  ^right_neighbor_of   $b        ) 
ONFAIL SAY("ring property violation detected!");
-----------------------------------------------------*/

/*  After the ring topology has been created, 
we can coordinate message exchange between neighbors, 
i.e. define the behavior of the ring */

COORDINATE  $m: Node    /* Default set, do the following for each Node */

DO  COORDINATE   $left:  Node SUCH THAT $left  left_neighbor_of  $m

    DO
        COORDINATE  $s1: send_left          FROM $m,
                    $r1: receive_from_right FROM $left
            DO ADD $s1 PRECEDES $r1; OD;

        COORDINATE  $s1: send_right        FROM $left,
                    $r1: receive_from_left FROM $m
            DO ADD $s1 PRECEDES $r1; OD;
    OD;
OD;
}; /* end of the BUILD block for the root Ring */
