/* Example 19, Consumers/Suppliers

Asynchronous coordination and dependency definition example.

user-defined relation related_to connects events within each 
single Request_delivery -> Consume chain

on Gryphon:
	scope 1, 2   traces, in less than 1 sec.
  	scope 2, 213 traces, approx. time 19 sec.
*/

SCHEMA Suppliers

/*=========================================*/
ROOT Consumers: {+ Consumer +};

Consumer: (* Request_delivery 

    		 ( Receive_supply  	| 

               Not_available 	) 
    	  *)
;

/*=======================================================================
	Supply_Office communicates asynchronously with Producers and Suppliers 
=========================================================================*/
ROOT Supply_Office: (*<1.. $$scope * $$scope> 
							/* Supply_Office serves several Consumers, 
								hence the iteration should be increased */
							Receive_order_and_buy 
					*);

/*======== coordination ===================================================*/
COORDINATE 	<!> $request: Request_delivery 				FROM Consumers,
			$receive_request: Receive_order_and_buy 	FROM Supply_Office
	DO
		ADD $request PRECEDES 		$receive_request;
		ADD $request related_to 	$receive_request;
	OD;

/*==========================================*/
ROOT Producers: {+ Producer +};	

Producer: (* ( Sell | Not_available ) *);

/*======== coordination ===================================================*/
COORDINATE 	$receive_order: Receive_order_and_buy 		FROM Supply_Office,
            /* Receive_order_and_buy and Sell/Not_available events 
			    may be asynchronous */
			<!> $sell: (Sell | Not_available) FROM Producers
	DO 	ADD $receive_order PRECEDES 	$sell; 
		ADD $receive_order related_to 	$sell; 
	OD;

COORDINATE 	$sell:  Sell 					FROM Producers,
				/* Sell and  Receive_supply may be asynchronous */
			<!> $receive: Receive_supply 	FROM Consumers
DO 	ADD $sell PRECEDES 		$receive; 
	ADD $sell related_to 	$receive; 
OD;

ENSURE FOREACH 	$request: Request_delivery, 
				$receive: Receive_supply
				( $request ^related_to 	$receive -> $request BEFORE $receive);

/* preventing mismatched delivery */
ENSURE 
	NOT EXISTS DISJ $c1: Consumer, $c2: Consumer
		EXISTS 	$request: Request_delivery 		FROM $c1, 
				$receive: Receive_supply 		FROM $c2,
				$order: Receive_order_and_buy FROM Supply_Office

        		( $request 	^related_to $order 		AND 
           	 	  $order  	^related_to $receive        );

COORDINATE 	<!>$refusal1: 	Not_available 	FROM Producers,
			$refusal2: 		Not_available 	FROM Consumers
	DO SHARE $refusal1 $refusal2; OD;

/* preventing mismatched refusals */
ENSURE  
NOT EXISTS DISJ $c1: Consumer, $c2: Consumer
		EXISTS 	$request: Request_delivery 		FROM $c1, 
				$receive: Not_available 		FROM $c2,
				$order: Receive_order_and_buy 	FROM Supply_Office

        		( $request 	^related_to $order 		AND 
           	 	  $order  	^related_to $receive        );

/**** add yet another relation for Supplier/Consumer ****/
COORDINATE $c: Consumer
	DO COORDINATE $p: Producer
		DO
	 		IF EXISTS 	$request: 	Request_delivery 	FROM $c, 
						$sell: 		Sell 				FROM $p
        		( $request ^related_to $sell )
        	THEN ADD $p Is_supplier_for $c; FI;
	OD;
OD; 
