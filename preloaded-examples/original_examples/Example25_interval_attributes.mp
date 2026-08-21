/* Example 25, Use of interval attributes.
    The task is to load a backpack with items not exceeding 
    the total weight of 30 units. 
    There may be several instances of the same item.

    run for scopes 1 and up
==========================================================*/
SCHEMA backpack

ATTRIBUTES{ interval weight; };

/* Composite event is used to define attribute value for 
    all instances of a particular event */
item1:   BUILD{ weight := [2..5];};
item2:   BUILD{ weight := [10..16];};

ROOT Backpack: (+ (item1 | item2)  +)
BUILD{ 
    COORDINATE $item: (item1 | item2) 
        DO  SAY("selected " $item " with weight " $item.weight);
            /* interval weight is initialized by [0..0] */
            weight +:= $item.weight; 
        OD; 
    /* ensure that the backpack's weight does not exceed maximum */
    ENSURE weight > 0 AND weight <= 30; };

SAY("selected " #(item1 | item2) " items");
SAY("backpack weight is within interval " Backpack.weight);
