/*  Example 21
    Compiler front end,
	bottom-up parser
	Lexer and parser in batch mode

run for 
scope 1, 2 traces, less than 1 sec.
scope 2, 147 traces, approx. time 0.87 sec.
scope 3, 11988 traces, approx. time 148 sec.
====================================================*/

SCHEMA compiler1

ROOT Source_code: (* get_characters 
    				 unget_some_characters *)
;

/*----------- lexical analysis ----------------*/
RegExpr_match:  match_string 
                [ largest_successful_match
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

/*--------- intermediate token list ----------*/
ROOT Token_list:
	(+ put_token +) (+ get_token +)
BUILD{
	ENSURE #put_token >= #get_token;
};

Token_list, Lexer SHARE ALL put_token;

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
	(+ 	(	Shift 			| 
			Reduce Put_node	) 
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

/*------ lexer and parser in the batch mode -------*/
Token_list, Parser SHARE ALL get_token;
