/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Prisoners Dilemma                         │ │
│*│ │  Created by Michael Collins on the 10th of         │ │
│*│ │     August, 2020.                                  │ │
│*│ │  Edited by Keane Reynolds in July, 2021.           │ │
│*│ │  Edited by Pamela Dyer in July and August, 2021.   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate using MP to model the logic of a    │ │
│*│ │ game scenario.                                     │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Users looking to model exhaustive logical game     │ │
│*│ │ scenarios may want to use this model as an         │ │
│*│ │ example.                                           │ │
│*│ │                                                    │ │
│*│ │ In this case, the classic model is the output in   │ │
│*│ │ the traces of the model with the payouts as        │ │
│*│ │ documented in (Straffin 1993).                     │ │
│*│ │                                                    │ │
│*│ │ Different in this MP model is how the payouts are  │ │
│*│ │ computed. Most models just assume the final amount │ │
│*│ │ of payouts for the matrix game.                    │ │
│*│ │                                                    │ │
│*│ │ Here the payout for Alice, and Bob respectively,   │ │
│*│ │ is computed from "Alice's view of the payoff for   │ │
│*│ │ each possible event independently of Bob's view"   │ │
│*│ │                                                    │ │
│*│ │ This is represented by the columns in the tables   │ │
│*│ │ below. A simple arithmetic derivation from those   │ │
│*│ │ columns is computed to have the trace generation   │ │
│*│ │ output each matrix element of the game as a        │ │
│*│ │ separate trace in the MP output.                   │ │
│*│ │                                                    │ │
│*│ │ Future work is to include other obvious matrices   │ │
│*│ │ readily constructed from this to be generated as   │ │
│*│ │ part of the trace generation.                      │ │
│*│ │                                                    │ │
│*│ │ This would represent something like a class of     │ │
│*│ │ matrix games to be constructed by the schema, one  │ │
│*│ │ of which would be the classic two person prisoners │ │
│*│ │ dilemma.                                           │ │
│*│ │                                                    │ │
│*│ │ Notice that this code is almost exactly like MP    │ │
│*│ │ native Example 14 -- number attributes. That       │ │
│*│ │ example is about a buyer purchasing different      │ │
│*│ │ products from different stores.                    │ │
│*│ │                                                    │ │
│*│ │ A related version of the prisoners dilemma to      │ │
│*│ │ shopping is documented at the Wikipedia article    │ │
│*│ │ cited below. "The donation game."                  │ │
│*│ │                                                    │ │
│*│ │ From Alice's viewpoint: (in this case the selfish  │ │
│*│ │ view point).                                       │ │
│*│ │  the payoff for Alice when she confesses      = 1. │ │
│*│ │  the payoff for Alice when Bob does not confess    │ │
│*│ │                                               = 2. │ │
│*│ │  in all other circumstances the payoff for Alice   │ │ 
│*│ │                                               = 0. │ │
│*│ │                                                    │ │
│*│ │ From Bob's viewpoint:   (in this case the selfish  │ │
│*│ │ view point)                                        │ │
│*│ │  the payoff for Bob when he confesses              │ │
│*│ │                                               = 1. │ │
│*│ │  the payoff for Bob when Alice does not confess    │ │
│*│ │                                               = 2. │ │
│*│ │  in all other circumstances the payoff for Bob     │ │
│*│ │                                               = 0. │ │
│*│ │                                                    │ │
│*│ │ To map it to classic values to show negative       │ │
│*│ │ payoffs -- that is a sort of normalizing. The      │ │
│*│ │ total payoff is computed from the assignments      │ │
│*│ │ above and then subtracting 2.                      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Straffin, Philip D. "12. The Prisoner's Dilemma."  │ │
│*│ │    in Game Theory and Strategy (New Mathematical   │ │
│*│ │    Library) 36, 36:73–80. Mathematical Association │ │
│*│ │    of America, 1993.                               │ │
│*│ │                                                    │ │
│*│ │ "Prisoner's dilemma." Wikipedia. Wikimedia         │ │
│*│ │    Foundation, September 5, 2021.                  │ │
│*│ │    https://en.wikipedia.org/wiki/Prisoner%27s_dilemma
│*│ │                                                    │ │
│*│ │ Kuhn, Steven. "Prisoner’s Dilemma." The Stanford   │ │
│*│ │    Encyclopedia of Philosophy. Winter, 2019.       │ │
│*│ │    https://plato.stanford.edu/entries/prisoner-dilemma/#Symm2t2PDOrdiPayo
│*│ │    https://plato.stanford.edu/archives/win2019/entries/prisoner-dilemma/
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, prisoners dilemma;                       │ │
│*│ │ behavior, matrix game; event attribute, number;    │ │
│*│ │ BUILD block; SAY statement; isomorphism            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 4 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

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
