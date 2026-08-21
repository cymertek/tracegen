/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Tic Tac Toe                               │ │
│*│ │  Created by Michael Collins in December, 2021.     │ │
│*│ │  Modified by Michael Collins and Pamela Dyer       │ │
│*│ │     in January through May, 2022.                  │ │
│*│ │                                                    | |
│*│ │  Many thanks to Emma Werking for providing the     │ │
│*│ │     technical foundations of this effort.          │ │
│*│ │  Many thanks to Kristin Giammarco for her insight  │ │
│*│ │     and recommendations.                           │ │
│*│ │  Many thanks to Michelle Morneau at the NPS        │ │
│*│ │     Graduate Writing Center for providing the      │ │
│*│ │     translation from our modeling dialects. This   │ │
│*│ │     helped with better communicating the project,  │ │
│*│ │     while also ensuring that the required technical│ │
│*│ │     precision was still maintained.                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate using MP to model simple strategies │ │
│*│ │ in the context of a game of Tic-tac-toe.           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ How to play Tic-tac-toe:                           | |
│*│ │ The game board is a 3 by 3 grid of cells.          | |
│*│ │ The player who goes first is known as 'X'.         | |
│*│ │ The player who goes second is known as 'O'.        | |
│*│ │ The players alternate placing Xs and Os on the     | |
│*│ │  board until either one of the players has three in| |
│*│ │  a line or until all cells on the grid are filled. | |
│*│ │                                                    | |
│*│ │ The goal is for X to never lose a game of          | |
│*│ │ Tic-Tac-Toe.                                       | |
|*| |                                                    | |
│*│ │ The following rules simplify the strategy:         | |
│*│ │     1) X never makes any mistakes.                 │ │
|*| |     2) O makes at most one mistake.                | |
│*│ │     3) X always chooses a corner on the first move | |
|*| |        of the game.                                | |
|*| |                                                    | |
│*│ │ Strategy: List all possible 2nd moves of the       | |
|*| |           game. Show how X can win or play to a    | |
|*| |           draw in each case by listing every move. | |
|*| |           When playing the game as X, use these    | |
|*| |           predetermined games as your directions   | |
|*| |           for how to play.                         | |
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Yates, James. "Tic Tac Toe Strategy Guide."        │ │
│*│ │ Chess and Poker Dot Com. Accessed April 6, 2022.   │ │
│*│ │https://www.chessandpoker.com/tic_tac_toe_strategy.html
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ tic-tac-toe; behavior, strategy; assertion checking│ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scope 1.                                   │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 5 traces in less than 1 sec.              │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Tic_tac_toe;
/*
Explanation:

  The 3x3 board with definitions for all cells:

     Corner | Remnant | Corner
    ----------------------------
     Remnant| Center  | Remnant
    ----------------------------
     Corner	| Remnant | Corner

    The center  cell has 0-outer edges.
    A   remnant cell has 1-outer edge.  ( corners are also edge cells )
    A   corner  cell has 2-outer edges.
*/

ROOT Strategy_based_on_2nd_move_of_the_game:
(
  choosing_remnant_next_to_X_on_2nd_move                 |/* Mistake, X wins  */
  choosing_remnant_NOT_beside_an_X_on_2nd_move           |/* Mistake, X wins  */
  choosing_a_corner_on_2nd_move                          |/* Mistake, X wins  */
  choosing_center_on_2nd_Move_and_any_corner_on_4th_move |/* Mistake, X wins  */
  choosing_center_on_2nd_Move_and_any_remnant_on_4th_move /* No mistakes,Draw */
);

/* Player going second makes mistake on second move of the game */
choosing_remnant_next_to_X_on_2nd_move :
 /* first   move */           X_chooses_corner
 /* second  move - mistake */ O_chooses_remnant_next_to_X_on_first_turn
 /* third   move */           X_chooses_center
 /* fourth  move */           O_blocks_
 /* fifth   move */           X_chooses_corner_NOT_beside_any_O
 /* sixth   move */           O_blocks
 /* seventh move */           X_wins;

/* Player going second makes mistake on second move of the game */
choosing_remnant_NOT_beside_an_X_on_2nd_move :
 /* first   move */           X_chooses_corner
 /* second  move - mistake */ O_chooses_remnant_NOT_beside_an_X_on_first_turn
 /* third   move */           X_chooses_center
 /* fourth  move */           O_blocks_
 /* fifth   move */           X_blocks
 /* sixth   move */           O_blocks
 /* seventh move */           X_wins;


/* Player going second makes mistake on second move of the game */
choosing_a_corner_on_2nd_move :
 /* first   move */           X_chooses_corner
 /* second  move - mistake */ O_chooses_corner
 /* third   move */           X_chooses_any_corner
 /* fourth  move */           O_blocks_
 /* fifth   move */           X_chooses_last_corner
 /* sixth   move */           O_blocks_one_path
 /* seventh move */           X_wins;


/* Player going second makes mistake on fourth move of the game */
choosing_center_on_2nd_Move_and_any_corner_on_4th_move :
 /* first   move */           X_chooses_corner
 /* second  move */           O_chooses_center
 /* third   move */           X_chooses_corner_opposite_previous_X
 /* fourth  move - mistake */ O_chooses_any_corner
 /* fifth   move */           X_blocks
 /* sixth   move */           O_blocks
 /* seventh move */           X_wins;


/* No mistakes made by either player */
choosing_center_on_2nd_Move_and_any_remnant_on_4th_move :
 /* first   move */           X_chooses_corner
 /* second  move */           O_chooses_center
 /* third   move */           X_chooses_corner_opposite_previous_X
 /* fourth  move */           O_chooses_any_remnant
 /* fifth   move */           X_blocks
 /* sixth   move */           O_blocks
 /* seventh move */           X_blocks
 /* eighth  move */           O_blocks
 /* ninth   move */           STALEMATE;

CHECK #X_wins == 1 OR #STALEMATE == 1
ONFAIL SAY ("X LOST!");











/*----------------COORDINATION SOLELY FOR VISUAL AID ___ */
/*NONE OF THIS COORDINATION CONSTRAINS OR INFLUENCES THE STRATEGY */
/* JUST VISUAL COMMENTARY FOR THE VIEWER */
COORDINATE $XEE_XEO: ( choosing_remnant_next_to_X_on_2nd_move |
                       choosing_remnant_NOT_beside_an_X_on_2nd_move )
DO
	ADD SAY("O chooses a remnant on second move.") PRECEDES $XEE_XEO;
OD;
COORDINATE $XEE_XEO: choosing_a_corner_on_2nd_move
DO
	ADD SAY("O chooses any corner on second move. ") PRECEDES $XEE_XEO;
OD;
COORDINATE $XOE: (
                   choosing_center_on_2nd_Move_and_any_corner_on_4th_move |
                   choosing_center_on_2nd_Move_and_any_remnant_on_4th_move
                 )
DO
	ADD SAY("O chooses center on second move.") PRECEDES $XOE;
OD;
COORDINATE $first_move: X_chooses_corner
DO
	ADD SAY("FIRST MOVE OF THE GAME.") PRECEDES $first_move;
OD;
COORDINATE $second_move:
 (
      O_chooses_remnant_next_to_X_on_first_turn           |
      O_chooses_remnant_NOT_beside_an_X_on_first_turn       |
      O_chooses_corner                                        |
      O_chooses_center
 )
DO
	ADD SAY("SECOND MOVE OF THE GAME.") PRECEDES $second_move;
OD;
COORDINATE $third_move:
 (
      X_chooses_center                         |
      X_chooses_any_corner                       |
      X_chooses_corner_opposite_previous_X
 )
DO
	ADD SAY("THIRD MOVE OF THE GAME.") PRECEDES $third_move;
OD;
COORDINATE $fourth_move:
        ( O_blocks_ | O_chooses_any_corner )
DO
	ADD SAY("FOURTH MOVE OF THE GAME."  ) PRECEDES $fourth_move;
	ADD SAY("X is now guaranteed to win") PRECEDES $fourth_move;
OD;
COORDINATE $fourth_move:  O_chooses_any_remnant
DO
	ADD SAY("FOURTH MOVE OF THE GAME."    ) PRECEDES $fourth_move;
	ADD SAY("STALEMATE IS NOW GUARANTEED ") PRECEDES $fourth_move;
OD;
/******************************************************************/
