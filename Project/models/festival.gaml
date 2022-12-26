/**
* Name: project
* Based on the internal empty template. 
* Author: gabrielemorello
* Tags: 
*/


model festival


global {
	int nb_stage <- 10; 
	int nb_guests <- 50;
	
	list<string> genres <- ["rock", "indie", "rap", "soul", "techno"];
	
	float inequality <- 0.0 update: standard_deviation((agents of_generic_species festival_guest) collect each.fun);
	float liking_threshold <- 0.6; // this defines the threshhold for when we determine someone to be a friend of ours or not
	
	lounge the_lounge;
	geometry shape <- square(20 #km);
	float step <- 10#mn;	
	
	string stage_at_location <- "stage_at_location";
    string empty_stage_location <- "empty_stage_location";
    
    predicate stage_location <- new_predicate(stage_at_location) ;
    predicate choose_stage <- new_predicate("choose a stage");
    predicate find_stage <- new_predicate("find stage") ;
    predicate tired <- new_predicate("tired");
    predicate chill <- new_predicate("chill") ;
    predicate share_information <- new_predicate("share information") ;
    
	matrix<float> likingMatrix <- matrix(
		// introvert, extrovert, security, addict, fighter
		[1.0, -0.8, 0.2, 0.4, 0.2], // introvert 
		[0.2, 1.0, 0.6, 0.4, -0.2], // extrovert 
		[0.4, 0.8, 1.0, 0.2, -0.6], // security
		[0.8, -0.6, 0.4, 1.0, 0.2], // addict
		[0.8, 0.4, -0.2, -0.6, 1.0] // fighter
	);
	
	init {
		create lounge {
			the_lounge <- self;
			location <- {10#km, 15#km};
		}
		// create stage number: nb_stage;
		create stage
		{
			location <- {3#km, 5#km};
		}
		create stage
		{
			location <- {8#km, 5#km};
		}
		create stage
		{
			location <- {13#km, 5#km};
		}
		create stage
		{
			location <- {18#km, 5#km};
		}
		// create festival_guest number: nb_listener;
		create introvert number: nb_guests / 5;
		create extrovert number: nb_guests / 5;
		create security number: nb_guests / 5;
		create addict number: nb_guests / 5;
		create fighter number: nb_guests / 5;
	}
	
	float getLikingForAgent(int currSpecies, int tarSpecies) 
	{
		return likingMatrix[tarSpecies, currSpecies];
	}
	
	rgb getLikingColor(float likingValue) {
		if (likingValue < 0.2) {
			return #red;
		} else if (likingValue < 0.4) {
			return #orange;
		} else if (likingValue < 0.6) {
			return #yellow;
		} else if (likingValue < 0.8) {
			return #blue;
		} else {
			return #green;
		}
	}
	
	reflex display_social_links{
        loop tempListener over: agents of_generic_species festival_guest {
                loop tempDestination over: tempListener.social_link_base {
                    if (tempDestination !=nil){
                        bool exists <- false;
                        loop tempLink over: socialLinkRepresentation {
                            if((tempLink.origin=tempListener) and (tempLink.destination=tempDestination.agent)){
                                exists <- true;
                            }
                        }
                        if(not exists) {
                            float destLiking <- get_liking(tempDestination);
                            rgb likingColor <- getLikingColor(destLiking);
                            create socialLinkRepresentation number: 1 {
                                origin <- tempListener;
                                destination <- tempDestination.agent;
                                my_color <- likingColor;
                            }
                        }
                    }
                }
            }
    }
	reflex end_simulation when: sum(stage collect each.quality) = 0 and empty(agents of_generic_species festival_guest where each.has_belief(tired)){
	    do pause;
	        ask festival_guest {
	        write name + " : " + fun;
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

species festival_guest skills: [moving] control:simple_bdi {
    float view_dist <- 1000.0;
    float speed <- 2#km/#h;
    rgb my_color <- rnd_color(255);
    point target;
    float fun <- 0.0;
    int tiredness;
    
    // this is used to determine when some other agents are "close enough"
    // such that they can be interacted with
	int nearbyDistanceThreshold <- 5;
    map<string, float> tastes;
    // this keeps track of which agents we've recently interacted with,
    // so we can avoid constantly high fiving someone near us, for example
	map<string, int> interactionMap <- [];
	// how many rounds to wait before we can interact with the same agent again
	int interactionResetLimit <- 10;
        
    rule belief: stage_location new_desire: tired strength: 2.0;
    rule belief: tired new_desire: chill strength: 3.0;
    
    init {
    	loop g over: genres {
    		tastes <- tastes + [g:: rnd(1.0)];
    	}
    	do add_desire(find_stage);
    }
    
	list<introvert> introvertAgents <- agents of_species introvert;
	list<extrovert> extrovertAgents <- agents of_species extrovert;
	list<security> securityAgents <- agents of_species security;
	list<fighter> fighterAgents <- agents of_species fighter;
	list<addict> addictAgents <- agents of_species addict;
    
    reflex initAgents
    {
		introvertAgents <- agents of_species introvert;
		extrovertAgents <- agents of_species extrovert;
		securityAgents <- agents of_species security;
		fighterAgents <- agents of_species fighter;
		addictAgents <- agents of_species addict;
    }
    
    reflex incrementInteractionMap
    {
		loop i from: 0 to: length(agents) - 1
		{
			agent currentAgent <- agents at i;
			int currentVal <- interactionMap[currentAgent.name];
			if (currentVal >= 0) {
				int nextVal <- currentVal + 1;
				write self.name + ": incrementing interaction map for: " + currentAgent.name + " to: " + nextVal;
				if (nextVal > interactionResetLimit)
				{
					interactionMap[currentAgent.name] <- -1;
				} else {
					interactionMap[currentAgent.name] <- currentVal + 1;	
				}
			} else {
				write self.name + ": current agent doesn't exist in interaction map: " + currentAgent.name;
			}
			
		}
    }
    
    action go_chill
    {
        do add_belief(tired); 
       	target <- nil;
    }
    
    perceive target: stage where (each.quality > 0) in: view_dist {
    	focus id: stage_at_location var:location;
    	ask myself {
	        do add_desire(predicate:share_information, strength: 5.0);
	        do remove_intention(find_stage, false);
    	}    	
    }
    
    // This will determine the likeability of guests within view_dist,
    // NOTE: this is executed in the context of the listener, not the
    // agent itself - therefore, we use "myself.tastes" to compare difference
    // in preferences.
    // TODO: This should be dependent on the association matrix written in the report,
    // i.e. each sub-species should set this likeability themselves.
    // TOOD: Perhaps this should only be done on initialization? Or only when guests
    // encounter eachother?
    perceive target: agents of_generic_species festival_guest in: view_dist {
    	point targetPoint <- point(tastes.values at 0, tastes.values at 1, tastes.values at 2, tastes.values at 3, tastes.values at 4);
    	point selfPoint <- point(myself.tastes.values at 0, myself.tastes.values at 1, myself.tastes.values at 2, myself.tastes.values at 3, myself.tastes.values at 4);
    	float l <- targetPoint distance_to selfPoint;
    	socialize liking: l;
    }
    
    
    // shares information to friends about known stages
    // TODO share more than just stage information?
    plan share_information_to_friends intention: share_information instantaneous: true {
	    list<festival_guest> my_friends <- list<festival_guest>((social_link_base where (each.liking > liking_threshold)) collect each.agent);
	    loop known_stage over: get_beliefs_with_name(stage_at_location) {
	        ask my_friends {
	            do add_directly_belief(known_stage);
	        }
	    }
    	do remove_intention(share_information, true); 
    }
    
    // TODO: Perhaps the guests should always know where
    // stages are located instead of wandering?
    plan lets_wander intention: find_stage {
    	do wander;
    }
    
	plan listen_music intention: tired {
	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_stage, true);
	        do current_intention_on_hold();
	    } else {
	        do goto target: target;
	        if (location distance_to(target) < 10)  {
		        stage current_stage <- stage first_with (target distance_to(each.location) < 10);
		        float appreciation <- tastes at current_stage.genre;
		        fun <- fun + current_stage.quality * appreciation;
		        tiredness <- tiredness + 1;
		        if (tiredness > 50) {
		        	do go_chill;
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

species introvert parent: festival_guest {
	int avoidThreshold <- 2;
	
	// TODO add probabilities for species

	reflex avoid when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > avoidThreshold
	{
		list<extrovert> extroverts <- extrovertAgents at_distance(nearbyDistanceThreshold);
		list<extrovert> newExtroverts <- [];
		loop i from: 0 to: length(extroverts) - 1
		{
			extrovert currentAgent <- extroverts at i;
			if interactionMap[currentAgent.name] >= 0
			{
				// avoid repeated interactions with same agents
				interactionMap[currentAgent.name] <- 1;
			} else {
				newExtroverts <- newExtroverts + currentAgent;
				interactionMap[currentAgent.name] <- 0;
			}
		}
		// TODO: reduce fun since extroverts made us reconsider our choice
		// TODO: don't run this when already in chill area?
		if length(newExtroverts) > 0
		{
			write self.name + ": extroverts nearby are annoying, taking a break";
			do go_chill;
		}
	}
	
	reflex appreciate when: length(securityAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": appreciating nearby security guards";
		// TODO appreciate security guards with FIPA?
	}
	
	reflex report when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": reporting nearby addicts";
		// TODO report substance abusers to security with FIPA?
	}
	
	reflex askToBeatUp when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0 and length(fighterAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": asking nearby fighters to beat up addicts";
		// TODO ask fighters to beat up guests with FIPA?
	}
}

species extrovert parent: festival_guest {
	reflex offerDrink when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": offering drink to nearby introverts";
		// TODO offer drink to introverts
	}
	
	reflex highFive when: length(securityAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": high fiving nearby security guards";
		// TODO high five security guards
	}
	
	reflex hypeUp when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": hyping up nearby addicts";
		// TODO hype up substance abusers
	}
	
	reflex avoid when: length(fighterAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		// TODO avoid fighters
		write self.name + ": avoiding nearby fighters";
		do go_chill;
	}
}

species fighter parent: festival_guest {
	reflex danceWith when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": dancing with a nearby introvert";
		// TODO dance with introverts
	}
	
	reflex threaten when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": threatening a nearby extrovert";
		// TODO threaten annoying guests (extroverts/dancers?)
	}
	
	reflex annoy when: length(securityAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": annoying nearby security guards";
		// TODO annoy guards (just to be an asshole)
	}
	
	reflex fight when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": starting a fight with nearby addicts";
		// TODO fight with substance abusers?
	}
}

species security parent: festival_guest {
	reflex cheerOn when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": cheering on nearby introverts";
		// TODO avoid current location if there are many unwanted guests (fighters and addicts?)
	}
	
	reflex highFive when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": high fiving nearby extroverts";
		// TODO invite nearby introverts to dance with us!
	}
	
	reflex arrestAddict when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": arresting nearby addict";
		// TODO report substance abusers to guards? send them to the chill area for a while?
	}
	
	reflex kickOut when: length(fighterAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": kicking out fighters";
		// TODO: only do this when fighters start fighting someone?
	}
}

species addict parent: festival_guest {
	
	reflex offerDrugs when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": offering drugs to nearby introverts";
		// TODO offer drugs to nearby introverts
	}
	
	reflex sellDrugs when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": selling drugs to nearby extroverts";
		// TODO sell drugs to nearby extroverts (and dancers?)
	}
	
	reflex avoid when: 	length(securityAgents 	at_distance(nearbyDistanceThreshold)) > 0 or
						length(fighterAgents 	at_distance(nearbyDistanceThreshold)) > 0
	{
		write self.name + ": avoiding guards/fighters nearby";
		do go_chill;
		// TODO avoid current location if there are fighters nearby, since they might beat us up
		// and security might arrest us
	}
}

species socialLinkRepresentation{
    festival_guest origin;
    agent destination;
    rgb my_color;
    
    aspect base{
        draw line([origin,destination],50.0) color: my_color;
    }
}


experiment festivalBdi type: gui {
    output {
	    display festivalMap type: opengl {
	        species lounge ;
	        species stage ;
	        species festival_guest;
	        species introvert;
	        species extrovert;
	        species security;
	        species addict;
	        species fighter;
	    }
	
	    display chart {
	        chart "Fun" type: series {
	        	datalist 
	        		legend: agents of_generic_species festival_guest accumulate each.name
	        		value: agents of_generic_species festival_guest accumulate each.fun
	        		color: agents of_generic_species festival_guest accumulate each.my_color;
	        }
	    }
	    display socialLinks type: opengl {
	        species socialLinkRepresentation aspect: base;
	    }
    }
}