/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 37. Model of Compiler in Interactive Mode  │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate component reuse between models,     │ │
│*│ │ emphasizing the advantages of separation between   │ │
│*│ │ the specification of component behavior and the    │ │
│*│ │ specification of interactions between components.  │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ Examples 36 and 37 are models of a bottom-up       │ │
│*│ │ parser with lexical analyzer based on regular      │ │
│*│ │ expression matching. It models the behavior of     │ │
│*│ │ Lex/Yacc generated compiler’s front end. Example   │ │
│*│ │ 36 represents an architecture where lexer stores   │ │
│*│ │ tokens in the intermediary data structure before   │ │
│*│ │ parser starts to access it, and this is a model    │ │
│*│ │ where parser works with the lexer interactively.   │ │
│*│ │ The Lexer part models the behavior of a typical    │ │
│*│ │ Lex machine. The behavior of Stack is integrated   │ │
│*│ │ into Parser’s behavior.                            │ │
│*│ │                                                    │ │
│*│ │ A reuse application of MP may involve either       │ │
│*│ │ another MP model, like an architecture template,   │ │
│*│ │ or part of it, like some particular root events    │ │
│*│ │ with interactions between them. These items can be │ │
│*│ │ stored in separate folders, and since the size of  │ │
│*│ │ MP code is relatively small, just copied/pasted    │ │
│*│ │ into the MP model under development. But they      │ │
│*│ │ still may require adjustment of relations between  │ │
│*│ │ the reused parts and the rest of MP model.         │ │
│*│ │ Interactions in MP (coordination operations) are   │ │
│*│ │ separated from the behavior descriptions (event    │ │
│*│ │ grammar rules), and such adjustment can be done in │ │
│*│ │ a declarative fashion by coordinating the reusable │ │
│*│ │ MP code and the MP code under development.         │ │
│*│ │ Examples 36 and 37 show how it can be done using a │ │
│*│ │ model of a compiler.                               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 35: Compiler’s front end in incremental   │ │
│*│ │ mode" from Auguston, M. "Monterey Phoenix System   │ │
│*│ │ and Software Architecture and Workflow Modeling    │ │
│*│ │ Language Manual" (Version 4). 2020. Available      │ │
│*│ │ online:                                            │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, compiler; reuse, component               │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1, 2, and 3.                        │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 2 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 111 traces in approx. 1.1 sec.            │ │
│*│ │ Scope 3: 4860 traces in approx. 1.6 min.           │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Compiler2

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
