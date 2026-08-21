/* Example23.mp number attribute test */

SCHEMA Shopping_spree

ROOT Buyer: (*<0.. 2 * $$scope>  Buy *);
/* Increase the iteration to ensure enough Buy events to coordinate with both Shops */

ATTRIBUTES{number 	price, total_cost;};

ROOT Shop_A: 	(* (Sell_Item_1 | Sell_Item_2) *)
/* Initializing attribute values in a context of composite event where these are used */
BUILD{  COORDINATE 	$s: Sell_Item_1 	DO $s.price:= 8; 	OD;
        COORDINATE 	$s: Sell_Item_2 	DO $s.price:= 20; 	OD; 
};

ROOT Shop_B: 	(* (Sell_Item_2 | Sell_Item_3) *)

/* In Shop_B the cost of Item_2 may be different */
BUILD{  COORDINATE 	$s: Sell_Item_2 	DO $s.price:= 22; 	OD; 
        COORDINATE 	$s: Sell_Item_3 	DO $s.price:= 30; 	OD; 
};

/* Schema’s attribute total_cost is automatically initialized by 0.0. 
    Absence of event reference means THIS by default  */
COORDINATE 	$sell: (Sell_Item_1 | Sell_Item_2 | Sell_Item_3),
            $buy: 	 Buy
    DO /* to render the dependency between sell and buy events */
        ADD $buy PRECEDES $sell;
    OD;

/* example of pre-defined attribute use */
SAY(" Trace #" trace_id);

/* use of aggregate operation to calculate total_cost as an attribute of the whole schema */
total_cost := SUM{ $item: (Sell_Item_1 | Sell_Item_2 | Sell_Item_3) APPLY $item.price};

SAY("Bought " #Buy " items. Total purchase cost is: " total_cost 
    " average cost: " total_cost/#Buy);
