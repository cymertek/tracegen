/*  Example 22
    Compiler front end,
	bottom-up parser
	Lexer and parser in interaction mode

run for 
scope 1, 2 traces, less than 1 sec.
scope 2, 111 traces, approx. time 0.65 sec.
scope 3, 4860 traces, approx. time 55 sec.
====================================================*/

SCHEMA compiler2

ROOT Source_code: (* get_characters 
    				 unget_some_characters *)
;

/*----------- lexical analysis ----------------*/
RegExpr_match:  match_string 
                [   largest_successful_match
                    put_token ]
;

Token_recognition: 	
					get_characters
					{+ RegExpr_match +}
					unget_some_characters 
BUILD{
	/* only one RegExpr_match succeeds */
	ENSURE #largest_successful_match == 1;
};

ROOT Lexer:
	(+ Token_recognition +)
;

Source_code, Lexer SHARE ALL get_characters, unget_some_characters;

/* ----- bottom-up parsing -------------------*/
Shift:  Push
        get_token
;

Reduce: (+<1..2> Pop +) 
        /* to tame the combinatorial explosion for nested iterations */
        Push 
;

Shift_Reduce:
	Push /* push the start non-terminal symbol */ 
	get_token
	(+ 	(	Shift 		| 
			Reduce 
			Put_node	) 
	+)

	(	Reduce 
		Put_node
		Parsing_complete 	|
 
		Report_syntax_error	)
;

Stack: (*<2 .. 2 * $$scope + 3 > (Push | Pop) *)
	/* extended iteration to provide 
		sufficient numbers of Pop and Push events */
BUILD{	ENSURE FOREACH $x: Pop 
				#Pop BEFORE $x < #Push BEFORE $x; 
};

ROOT Parser:    {Shift_Reduce, Stack}
BUILD{  COORDINATE  $s1: Shift_Reduce,
                    $s2: Stack
            DO $s1, $s2 SHARE ALL Pop, Push; OD;
};

/*------ lexer and parser in the interactive mode -------*/
COORDINATE 	$produce_token: put_token FROM Lexer,
			$consume_token: get_token FROM Parser
	DO ADD $produce_token PRECEDES $consume_token; OD;
