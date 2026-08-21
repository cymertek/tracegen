/*┬────────────────────────────────────────────────────────┐
│*│ ┌─[ Title and Authors ]──────────────────────────────┐ │
│*│ │ Example 14. Model of Shopping Spree                │ │
│*│ │  Created by Mikhail Auguston                       │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Purpose ]────────────────────────────────────────┐ │
│*│ │ To demonstrate the use of event number attributes  │ │
│*│ │ for calculating a total cost for each event trace  │ │
│*│ │ and an average cost of items across all events in  │ │
│*│ │ a trace.                                           │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Description ]────────────────────────────────────┐ │
│*│ │ In this model, a Buyer goes to two different shops │ │
│*│ │ that are selling items. Each item has a price. The │ │
│*│ │ event traces generated show all possible           │ │
│*│ │ combinations of shopping scenarios from the model  │ │
│*│ │ within the scope. Number attributes "price" and    │ │
│*│ │ "total_cost" are used to compute total shopping    │ │
│*│ │ spree cost and the average cost of items in each   │ │
│*│ │ event trace. In this model the number attributes   │ │
│*│ │ are initialized with values in BUILD blocks for    │ │
│*│ │ the roots holding the corresponding events.        │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ References ]─────────────────────────────────────┐ │
│*│ │ "Example 21: Attribute use" from Auguston, M.      │ │
│*│ │ "Monterey Phoenix System and Software Architecture │ │
│*│ │ and Workflow Modeling Language Manual"             │ │
│*│ │ (Version 4). 2020. Available online:               │ │
│*│ │ https://wiki.nps.edu/display/MP/Documentation      │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Search Terms ]───────────────────────────────────┐ │
│*│ │ behavior, shopping spree; event attribute, number; │ │
│*│ │ BUILD block; SAY statement; isomorphism            │ │
│*│ └────────────────────────────────────────────────────┘ │
│*│                                                        │
│*│ ┌─[ Instructions ]───────────────────────────────────┐ │
│*│ │ Run for Scopes 1 and up.                           │ │
│*│ ├─[ Run Statistics ]─────────────────────────────────┤ │
│*│ │ Scope 1: 9 traces in less than 1 sec.              │ │
│*│ │ Scope 2: 49 traces in less than 1 sec.             │ │
│*│ │ Scope 3: 225 traces in less than 1 sec.            │ │
│*│ └────────────────────────────────────────────────────┘ │
└*┴───────────────────────────────────────────────────────*/

SCHEMA Shopping_Spree

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
