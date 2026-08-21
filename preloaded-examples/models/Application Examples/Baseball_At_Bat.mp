/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Model of Baseball At Bat                           │ │
│*│ │  Created by Pamela Dyer in July, 2021.             │ │
│*│ │  Edited by Pamela Dyer in August, 2021.            │ │
│*│ │  Edited by Pamela Dyer in February, 2022.          │ │
│*│ │  Edited by Pamela Dyer in March, 2022.             │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To                                                 │ │
│*│ │ 1) demonstrate several different aspects of ENSURE │ │
│*│ │    in MP, including the use of inequalities within │ │
│*│ │    ENSURE constraints, and                         │ │
│*│ │ 2) show that MP can be used to model results from  │ │
│*│ │    interactions that are found in a very well-known│ │
│*│ │    game such as Baseball. This model illustrates   │ │
│*│ │    a baseball at bat with 1 Pitcher and 1 Batter.  │ │
│*│ │    It is important to note, though, that this model│ │
│*│ │    shows only a selection of all of the possible   │ │
│*│ │    Batter outcomes that can actually occur in the  │ │
│*│ │    game of Baseball.                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Scope 1 shows the possible outcomes for the Batter │ │
│*│ │ once receiving 1 pitch from the Pitcher. Scopes 2, │ │
│*│ │ 3, 4, and 5 show the possible outcomes for 2, 3, 4,│ │
│*│ │ and 5 pitches, respectively. There are certain     │ │
│*│ │ outcomes (events) that end the at bat, which means │ │
│*│ │ there is no further pitch after them. These can    │ │
│*│ │ occur after the 1st, 2nd, 3rd, or later pitch,     │ │
│*│ │ depending on specifics with regards to the rules   │ │
│*│ │ of Baseball. For example: if on the 1st pitch the  │ │
│*│ │ Batter hits a Fly Ball and it is caught by the     │ │
│*│ │ opponent, the at bat ends. Scope 2 will never have │ │
│*│ │ traces where a Fly Ball was caught on the 1st pitch│ │
│*│ │ and another event happened on the 2nd pitch -      │ │
│*│ │ impossible with only 1 Batter.                     │ │
│*│ │                                                    │ │
│*│ │ A snapshot of typical baseball occurrences are     │ │
│*│ │ highlighted in the Pitcher and Batter root events. │ │
│*│ │ Fastball, Breaking_Ball, and Changeup represent the│ │
│*│ │ three main categories of baseball pitches. The     │ │
│*│ │ composite events No_Swing, Swing_and_Miss,         │ │
│*│ │ Swing_and_Foul, and Swing_and_Fair are four broad  │ │
│*│ │ categories representing what the Batter can do with│ │
│*│ │ the incoming pitch. The atomic events Ball,        │ │
│*│ │ Strike_Looking, and Strike_Swinging all have an    │ │
│*│ │ optional event following them that is enclosed in  │ │
│*│ │ square brackets [ ]. One of the atomic events under│ │
│*│ │ Swing_and_Foul and all of the atomic events under  │ │
│*│ │ Swing_and_Fair have an additional event following  │ │
│*│ │ them that always occurs afterwards.                │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ Dhakar, Lokesh. "Baseball pitches illustrated."    │ │
│*│ │    Baseball pitches illustrated | Lokesh Dhakar.   │ │
│*│ │    Accessed March 14, 2022.                        │ │
│*│ │    https://lokeshdhakar.com/baseball-pitches-illustrated/
│*│ │                                                    │ │
│*│ │ "Walk (BB): Glossary." MLB.com.                    │ │
│*│ │    Accessed March 14, 2022.                        │ │
│*│ │    https://www.mlb.com/glossary/standard-stats/walk│ │
│*│ │                                                    │ │
│*│ │ "Strikeout (SO, K): Glossary." MLB.com.            │ │
│*│ │    Accessed March 14, 2022.                        │ │
│*│ │    https://www.mlb.com/glossary/standard-stats/strikeout
│*│ │                                                    │ │
│*│ │ "Hit." Sports Definitions. Accessed March 14, 2022.│ │
│*│ │    https://www.sportsdefinitions.com/baseball/hit/ │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, baseball at bat; coordination, event;    │ │
│*│ │ ENSURE condition; SAY statement; trace annotation; │ │
│*│ │ coordination, nested composition                   │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up. It is important to note   │ │
│*│ │ that starting at Scope 3 and above, graphing all   │ │
│*│ │ generated traces does take some time when using    │ │
│*│ │ MP-Firebird, as will the inspection of the traces. │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 39 traces in less than 1 sec.             │ │
│*│ │ Scope 2: 507 traces in less than 1 sec.            │ │
│*│ │ Scope 3: 6123 traces in approx. 1.2 min.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Baseball_At_Bat



ROOT Pitcher: Choose_Pitch;

		Choose_Pitch: (+ ( Fastball | Breaking_Ball | Changeup ) +);

ROOT Batter: (+ ( No_Swing | Swing_and_Miss | Swing_and_Foul | Swing_and_Fair ) +);

		No_Swing: ( Ball [ WALK ] | Strike_Looking [ STRIKEOUT ] );

		Swing_and_Miss: Strike_Swinging [ STRIKEOUT ];

		Swing_and_Foul: ( Strike_Foul | NonStrike_Foul | Caught_Foul OUT );

		Swing_and_Fair: ( Single HIT | Double HIT | Triple HIT | Home_Run HIT | 

              Caught_Line_Drive OUT | Caught_Pop_Up OUT | Caught_Fly_Ball OUT | 

              Fielded_Grounder_thrown_to_First_Base OUT );


COORDINATE	$x: ( Fastball | Breaking_Ball | Changeup )  FROM Pitcher,
			 $y: ( No_Swing | 
                       Swing_and_Miss | 
                 	       Swing_and_Foul | 
                 		       Swing_and_Fair )  FROM Batter
	DO ADD $x PRECEDES $y; OD;



/* The number of Balls in the at bat can never exceed 4. */
ENSURE #Ball <= 4;

/* If the number of Balls in the at bat is less than 4, the Batter cannot Walk.
Also: If the Batter did not Walk, the number of Balls in the at bat was 
less than 4. */
ENSURE #Ball < 4 <-> #WALK == 0;

/* If the number of Balls in the at bat is equal to 4, the Batter does Walk.
Also: If the Batter did Walk, the number of Balls in the at bat was 
equal to 4. */
ENSURE #Ball == 4 <-> #WALK == 1;

/* If the Batter does Walk, then there cannot be another pitch to the Batter.
Therefore, with a Walk, the at bat always ends. This is because WALK means 
Batter takes first base safely. */
COORDINATE $w: WALK
	DO ENSURE #$$EVENT AFTER $w == 0;
    OD;


/* The number of Strikes the Batter can receive from hitting the baseball into 
Foul territory during the at bat can never exceed 2. Strike_Foul cannot be the 
3rd and final strike. */
ENSURE #Strike_Foul <= 2;

/* The NonStrike_Foul count cannot begin until at least the 3rd pitch. Here the 
meta-symbol $$ATOM is referring to any atomic event that is present prior to 
NonStrike_Foul in any given trace. Therefore, the "greater than or equal to 5" 
below comes from the minimum requirement: 2 previous pitches + 2 Batter results 
from those pitches + 1 additional pitch. NonStrike_Foul may occur for the first 
time as the Batter result from that additional (3rd) pitch. */
COORDINATE $n: NonStrike_Foul
	DO ENSURE #$$ATOM BEFORE $n >= 5;
	OD;

/* In addition to the COORDINATE statement just above, it is also a requirement 
that the total number of Strikes in the at bat (from any combination of 
Strike_Looking, Strike_Swinging, and Strike_Foul) is equal to 2 before the 
NonStrike_Foul count can begin. The term NonStrike_Foul is essentially just 
referring to any time the Batter hits the baseball into Foul territory after 
having already accumulated 2 strikes. In the game of Baseball, there is no set 
end value for how many times a Batter can hit the baseball into Foul territory 
during an at bat. */
COORDINATE $n: NonStrike_Foul
	DO ENSURE #Strike_Looking + #Strike_Swinging + #Strike_Foul == 2;
	OD;


/* The total number of Strikes the Batter can receive during the at bat 
(from any combination of Strike_Looking, Strike_Swinging, and Strike_Foul) 
can never exceed 3. */
ENSURE #Strike_Looking + #Strike_Swinging + #Strike_Foul <= 3;

/* If the total number of Strikes in the at bat is less than 3, then the Batter 
cannot receive a Strikeout. Also, if the Batter did not receive a Strikeout, 
then the total number of Strikes in the at bat was less than 3. */
ENSURE #Strike_Looking + #Strike_Swinging + #Strike_Foul < 3 <-> #STRIKEOUT == 0;

/* If the total number of Strikes in the at bat is equal to 3, then the Batter 
receives a Strikeout. Also, if the Batter received a Strikeout, then the 
total number of Strikes in the at bat was equal to 3. */
ENSURE #Strike_Looking + #Strike_Swinging + #Strike_Foul == 3 <-> #STRIKEOUT == 1;

/* If the Batter does receive a Strikeout, then there cannot be another pitch 
to the Batter. Therefore, with a Strikeout, the at bat always ends. */
COORDINATE $s: STRIKEOUT
	DO ENSURE #$$EVENT AFTER $s == 0;
    OD;


/* If the Batter gets Out resulting from any of the applicable events shown 
above, then there cannot be another pitch to the Batter. Therefore, with an Out, 
the at bat always ends. */
COORDINATE $o: OUT
	DO ENSURE #$$EVENT AFTER $o == 0;
    OD;

/* If the Batter gets a Hit resulting from any of the applicable events shown 
above, then there cannot be another pitch to the Batter. Therefore, with a Hit, 
the at bat always ends. This is because HIT means Batter safely reaches or 
passes first base. */
COORDINATE $h: HIT
	DO ENSURE #$$EVENT AFTER $h == 0;
    OD;



/* If the number of Balls recorded during the at bat is equal to 4, then those 
traces will be annotated with a message that the Batter did Walk. */
IF #Ball == 4 THEN
	SAY("BB (WALK)");
FI;


/* If the total number of Strikes recorded during the at bat equals 3, those 
traces will be annotated with a message that the Batter received a Strikeout. */
IF #Strike_Looking + #Strike_Swinging + #Strike_Foul == 3 THEN
	SAY("STRIKEOUT");
FI;


/* If Strike_Looking is the event immediately preceding STRIKEOUT, then 
those traces will be annotated with an additional message that the at bat ended 
in a Strikeout Looking, which in Baseball is denoted by a ꓘ. */
COORDINATE $b: STRIKEOUT
	DO COORDINATE $a: Strike_Looking SUCH THAT $a PRECEDES $b
		DO
			ADD SAY("ꓘ (Strikeout Looking)")
				PRECEDES $a;
		OD;
	OD;


/* If Strike_Swinging is the event immediately preceding STRIKEOUT, then 
those traces will be annotated with an additional message that the at bat ended 
in a Strikeout Swinging, which in Baseball is denoted by a K. */
COORDINATE $d: STRIKEOUT
	DO COORDINATE $c: Strike_Swinging SUCH THAT $c PRECEDES $d
		DO
			ADD SAY("K (Strikeout Swinging)")
				PRECEDES $c;
		OD;
	OD;


/* It is necessary to note again that the event Strike_Foul cannot be the event 
immediately preceding STRIKEOUT. Also, this model does not take into account 
certain nuances that can occur on 3rd strikes, such as foul tips and instances 
where the catcher does not cleanly hold onto the baseball, for example. */


/* Shown below are the remaining trace annotations for if any of the applicable 
events occur once, all of which end the at bat. */
IF #Caught_Foul > 0 THEN
	SAY("OUT - Foul Out");
FI;


IF #Single > 0 THEN
	SAY("HIT - 1B (Single)");
FI;


IF #Double > 0 THEN
	SAY("HIT - 2B (Double)");
FI;


IF #Triple > 0 THEN
	SAY("HIT - 3B (Triple)");
FI;


IF #Home_Run > 0 THEN
	SAY("HIT - HR (Home Run)");
FI;


IF #Caught_Line_Drive > 0 THEN
	SAY("OUT - Line Out");
FI;


IF #Caught_Pop_Up > 0 THEN
	SAY("OUT - Pop Out");
FI;


IF #Caught_Fly_Ball > 0 THEN
	SAY("OUT - Fly Out");
FI;


IF #Fielded_Grounder_thrown_to_First_Base > 0 THEN
	SAY("OUT - Ground Out");
FI;

