/**
* Name: project
* Based on the internal empty template. 
* Author: gabrielemorello
* Tags: 
*/


model souvenirs

global {
	int nb_stand <- 10; 
	int nb_collector <- 50;
	
	float inequality <- 0.0 update:standard_deviation(collector collect each.souvenir_sold);
	
	market the_market;
	geometry shape <- square(20 #km);
	float step <- 10#mn;	
	
	string stand_at_location <- "mine_at_location";
    string empty_stand_location <- "empty_mine_location";
    
    predicate stand_location <- new_predicate(stand_at_location) ;
    predicate choose_stand <- new_predicate("choose a stand");
    predicate has_souvenir <- new_predicate("collect souvenir");
    predicate find_souvenir <- new_predicate("find souvenir") ;
    predicate sell_souvenir <- new_predicate("sell souvenir") ;
	
	init {
		create market {
			the_market <- self;
		}
		create stand number: nb_stand;
		create collector number: nb_collector;
	}
	reflex end_simulation when: sum(stand collect each.quantity) = 0 and empty(collector where each.has_belief(has_souvenir)){
	    do pause;
	        ask collector {
	        write name + " : " +souvenir_sold;
	    }
    }
	
}

species stand {
	int quantity <- rnd(1,200);
	aspect default {
		draw triangle(200 + quantity * 5) color: (quantity > 0) ? #yellow : #gray border: #black;	
	}
}

species market {
	int souvenirs;
	aspect default {
	  draw square(1000) color: #black ;
	}
}

species collector skills: [moving] control:simple_bdi {
    float view_dist <- 1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
    int souvenir_sold;
    
    rule belief: stand_location new_desire: has_souvenir strength: 2.0;
    rule belief: has_souvenir new_desire: sell_souvenir strength: 3.0;
    
    init {
    	do add_desire(find_souvenir);
    }
    
    perceive target: stand where (each.quantity > 0) in: view_dist {
    	focus id: stand_at_location var:location;
    	ask myself {
        	do remove_intention(find_souvenir, false);
    	}
    }
    
    plan lets_wander intention: find_souvenir {
    	do wander;
    }
    
	plan get_souvenir intention:has_souvenir {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_stand, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target ;
	        if (target = location)  {
		        stand current_stand<- stand first_with (target = each.location);
		        if current_stand.quantity > 0 {
		            do add_belief(has_souvenir);
		            ask current_stand {
		            	quantity <- quantity - 1;
		            }    
		        } else {
		            do add_belief(new_predicate(empty_stand_location, ["location_value"::target]));
		        }
		        target <- nil;
	        }
	    }   
	}
	
	plan choose_closest_stand intention: choose_stand instantaneous: true {
	    list<point> possible_stands <- get_beliefs_with_name(stand_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    list<point> empty_stands <- get_beliefs_with_name(empty_stand_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    possible_stands <- possible_stands - empty_stands;
	    if (empty(possible_stands)) {
	        do remove_intention(has_souvenir, true); 
	    } else {
	        target <- (possible_stands with_min_of (each distance_to self)).location;
	    }
	    do remove_intention(choose_stand, true); 
    }
	
	plan return_to_base intention: sell_souvenir {
	    do goto target: the_market ;
	    if (the_market.location = location)  {
	        do remove_belief(has_souvenir);
	        do remove_intention(sell_souvenir, true);
	        souvenir_sold <- souvenir_sold + 1;
	    }
    }

    aspect default {
        draw circle(200) color: my_color border: #black depth: souvenir_sold;
        draw circle(view_dist) color: my_color border: #black depth: souvenir_sold wireframe: true;
    }
}

experiment souvenirBdi type: gui {
    output {
    display map type: opengl {
        species market ;
        species stand ;
        species collector;
    }

        display chart {
        chart "Money" type: series {
        datalist legend: collector accumulate each.name value: collector accumulate each.souvenir_sold color: collector accumulate each.my_color;
        }
    }

    }
}