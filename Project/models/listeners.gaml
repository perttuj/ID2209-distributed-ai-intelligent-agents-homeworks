/**
* Name: project
* Based on the internal empty template. 
* Author: gabrielemorello
* Tags: 
*/


model listeners


global {
	int nb_stage <- 10; 
	int nb_listener <- 50;
	
	list<string> genres <- ["rock", "indie", "rap", "soul", "techno"];
	
	float inequality <- 0.0 update:standard_deviation(listener collect each.fun);
	
	lounge the_lounge;
	geometry shape <- square(20 #km);
	float step <- 10#mn;	
	
	string stage_at_location <- "mine_at_location";
    string empty_stage_location <- "empty_mine_location";
    
    predicate stage_location <- new_predicate(stage_at_location) ;
    predicate choose_stage <- new_predicate("choose a stage");
    predicate find_stage <- new_predicate("find stage") ;
    predicate tired <- new_predicate("tired");
    predicate chill <- new_predicate("chill") ;
    predicate share_information <- new_predicate("share information") ;
    
	
	init {
		create lounge {
			the_lounge <- self;
		}
		create stage number: nb_stage;
		create listener number: nb_listener;
	}
	
	reflex display_social_links{
        loop tempListener over: listener{
                loop tempDestination over: tempListener.social_link_base{
                    if (tempDestination !=nil){
                        bool exists<-false;
                        loop tempLink over: socialLinkRepresentation{
                            if((tempLink.origin=tempListener) and (tempLink.destination=tempDestination.agent)){
                                exists<-true;
                            }
                        }
                        if(not exists){
                            create socialLinkRepresentation number: 1{
                                origin <- tempListener;
                                destination <- tempDestination.agent;
                                if(get_liking(tempDestination)>0.6){
                                    my_color <- #green;
                                } else {
                                    my_color <- #red;
                                }
                            }
                        }
                    }
                }
            }
    }
	reflex end_simulation when: sum(stage collect each.quality) = 0 and empty(listener where each.has_belief(tired)){
	    do pause;
	        ask listener {
	        write name + " : " +fun;
	    }
    }
	
}

species stage {
	int quality <- rnd(1,10);
	string genre <- (1 among genres) at 0;
	aspect default {
		draw triangle(200 + quality * 50) color: (quality > 0) ? #yellow : #gray border: #black;	
	}
}

species lounge {
	aspect default {
	  draw square(1000) color: #black ;
	}
}

species listener skills: [moving] control:simple_bdi {
    float view_dist <- 1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
    float fun <- 0.0;
    int tiredness;
    
    map tastes;
        
    rule belief: stage_location new_desire: tired strength: 2.0;
    rule belief: tired new_desire: chill strength: 3.0;
    
    init {
    	loop g over: genres {
    		tastes <- tastes + [g:: rnd(1.0)];
    	}
    	do add_desire(find_stage);
    }
    
    perceive target: stage where (each.quality > 0) in: view_dist {
    	focus id: stage_at_location var:location;
    	ask myself {
        do add_desire(predicate:share_information, strength: 5.0);
        do remove_intention(find_stage, false);
    	}    	
    }
    
    perceive target: listener in: view_dist {
    	float l <- point(tastes.values at 0, tastes.values at 1, tastes.values at 2, tastes.values at 3, tastes.values at 4) distance_to point(myself.tastes.values at 0, myself.tastes.values at 1, myself.tastes.values at 2, myself.tastes.values at 3, myself.tastes.values at 4);
    	socialize liking: l;
    	write l;
    }
    
    
    plan share_information_to_friends intention: share_information instantaneous: true{
	    list<listener> my_friends <- list<listener>((social_link_base where (each.liking > 0.6)) collect each.agent);
	    loop known_stage over: get_beliefs_with_name(stage_at_location) {
	        ask my_friends {
	            do add_directly_belief(known_stage);
	        }
	    }
    	do remove_intention(share_information, true); 
    }
    
    plan lets_wander intention: find_stage {
    	do wander;
    }
    
	plan listen_music intention:tired {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_stage, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target ;
	        if (target = location)  {
		        stage current_stage <- stage first_with (target = each.location);
		        float appreciation <- tastes at current_stage.genre;
		        fun <- fun + current_stage.quality * appreciation;
		        tiredness <- tiredness + 1;
		        if (tiredness > 50) {
		            do add_belief(tired); 
		           	target <- nil;
		        }
	        }
	    }   
	}
	
	
	plan choose_closest_stage intention: choose_stage instantaneous: true {
	    list<point> possible_stages <- get_beliefs_with_name(stage_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    if (empty(possible_stages)) {
	        do remove_intention(tired, true); 
	    } else {
	        target <- (possible_stages with_min_of (each distance_to self)).location;
	    }
	    do remove_intention(choose_stage, true); 
    }
	
	plan return_to_base intention: chill {
	    do goto target: the_lounge ;
	    if (the_lounge.location = location)  {
			tiredness <- tiredness-1;
	    	
	    	if (tiredness <= 0){
	        	do remove_belief(tired);
	        	do remove_intention(chill, true);
	        }
	    }
    }


	
    aspect default {
        draw circle(200) color: my_color border: #black depth: fun;
        draw circle(view_dist) color: my_color border: #black depth: fun wireframe: true;
    }
}

species socialLinkRepresentation{
    listener origin;
    agent destination;
    rgb my_color;
    
    aspect base{
        draw line([origin,destination],50.0) color: my_color;
    }
}


experiment souvenirBdi type: gui {
    output {
	    display map type: opengl {
	        species lounge ;
	        species stage ;
	        species listener;
	    }
	
	    display chart {
	        chart "Fun" type: series {
	        datalist legend: listener accumulate each.name value: listener accumulate each.fun color: listener accumulate each.my_color;
	        }
	    }
	    display socialLinks type: opengl{
	        species socialLinkRepresentation aspect: base;
	    }
    }
}