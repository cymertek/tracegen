/* The Prisoner's Dilemma 
Michael Collins
August 10, 2020.
https://en.wikipedia.org/wiki/Prisoner%27s_dilemma
https://plato.stanford.edu/entries/prisoner-dilemma/#Symm2t2PDOrdiPayo

In this case, the classic model is the output in the traces
of the model with the payouts as documented in 
"Game Theory and Strategy" by Philip D. Straffin
Mathematical Association of America 1993
isbn: 0-88385-637-9
Chapter 12, page 73.

Different in this MP model is how the payouts
are computed.  Most models just assume the final
amount of payouts for the matrix game. 

Here the payout for Alice, and Bob respectively,
is computed from 
"Alice's view of the payoff for each possible event independently of Bob's view"

This is represented by the columns in the tables below. 
A simple arithmetic derivation from those columns is computed to have the 
trace generation output each matrix element of the game as 
a separate trace in the MP output. 

Future work is to include other obvious matrices readily constructed 
from this to be generated as part of the trace generation.

This would represent something like a class of matrix games 
to be constructed by the schema, one of which would be 
the classic two person prisoners dilemma

Notice that this code is almost exactly like
MP native Example 23 -- number attributes. 
That example is about a buyer purchasing different products
from different stores.  

A related version of the prisoners dilemma to shopping is
documented at the Wikipedia article cited above. "The donation game."

This model is only meant to be run at scope 1.  

From Alice's viewpoint: (in this case the selfish view point). 
the payoff for Alice when she confesses         = 1.
the payoff for Alice when Bob does not confess  = 2. 
in all other circumstances the payoff for Alice = 0.

From Bob's viewpoint:   (in this case the selfish view point)
the payoff for Bob when he confesses            = 1.
the payoff for Bob when Alice does not confess  = 2.
in all other circumstances the payoff for Bob   = 0.

To map it to classic values to show negative payoffs -- that is a sort of normalizing. 
The total payoff is computed from the assignments above and then subtracting 2. 

*/


/*—————————————————————————————
 	 		  Actors
———————————————————————————————*/
SCHEMA Prisoners_Dilemma

ATTRIBUTES { number utility1, utility2, payout_alice, payout_bob ;};


do_not_confess_alice: BUILD{ utility1:=  0 ; utility2:= 2 ;};
confess_alice:        BUILD{ utility1:=  1 ; utility2:= 0 ;};
do_not_confess_bob  : BUILD{ utility1:=  2 ; utility2:= 0 ;};
confess_bob:          BUILD{ utility1:=  0 ; utility2:= 1 ;};


ROOT Alice: ( do_not_confess_alice | confess_alice );

ROOT Bob:   ( do_not_confess_bob   | confess_bob   );

payout_alice:= SUM{ $act:( do_not_confess_alice | confess_alice | do_not_confess_bob | confess_bob ) APPLY $act.utility1  } - 2 ;
payout_bob  := SUM{ $act:( do_not_confess_alice | confess_alice | do_not_confess_bob | confess_bob ) APPLY $act.utility2  } - 2 ;


/*—————————————————————————————
 		        Interactions
———————————————————————————————*/
SAY( "Payout Alice = " payout_alice);
SAY( "Payout Bob   = " payout_bob  );