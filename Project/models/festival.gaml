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

	float liking_threshold <- 0.6; // this defines the threshhold for when we determine someone to be a friend of ours or not
	
	lounge the_lounge;
	jail the_jail;
	geometry shape <- square(20 #km);
	float step <- 10#mn;	
	
	bool debug <- false;
	
	string stage_at_location <- "stage_at_location";
    
    predicate stage_location <- new_predicate(stage_at_location) ;
    predicate choose_stage <- new_predicate("choose a stage");
    predicate find_stage <- new_predicate("find stage");
    predicate dance_at_stage <- new_predicate("dance near stage");
    predicate tired <- new_predicate("tired");
    predicate chill <- new_predicate("chill");
    predicate share_information <- new_predicate("share information");
    predicate arrested <- new_predicate("arrested");
    predicate free <- new_predicate("free");
    
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
			location <- {10#km, 10#km};
		}
		// create stage number: nb_stage;
		create stage
		{
			location <- {5#km, 5#km};
		}
		create stage
		{
			location <- {5#km, 15#km};
		}
		create stage
		{
			location <- {15#km, 5#km};
		}
		create stage
		{
			location <- {15#km, 15#km};
		}
		create jail
		{
			the_jail <- self;
			location <- {10#km, 15#km};
		}
		// create festival_guest number: nb_guests;
		
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
	
	action display_social_links {
        loop tempListener over: agents of_generic_species introvert {
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
        write "LOL";
    }
    
    reflex update_links when: (cycle mod 1000) = 1
    {
    	do display_social_links;
    }
    
	reflex print_inequality when: (cycle mod 100) = 0 {
		list<float> vals <- (agents of_generic_species festival_guest) collect each.fun;
    	float std <- standard_deviation(vals);
    	float mean <- mean(vals);
	    write self.name + ": standard deviation = " + std + ", mean: " + mean;
    }
	
}

species stage {
	int quality <- rnd(1,10);
	string genre <- (1 among genres) at 0;
	aspect default {
		draw triangle(1500) color: (quality > 0) ? #yellow : #gray border: #black;	
	}
}

species lounge {
	aspect default {
	  draw square(1000) color: #black ;
	}
}

species jail {
	aspect default{
		draw square(1000) color: #grey;
	}
}

species festival_guest skills: [moving, fipa] control: simple_bdi {
    float view_dist <- 1000.0;
    float speed <- 2#km/#h;
    rgb my_color;
    point target;
    float fun <- 0.0;
    int tiredness;
    int sentence;
    int agentIndex;
    bool initialized <- false;
    list<point> possible_stages;
  
    // this is used to determine when some other agents are "close enough"
    // such that they can be interacted with
	int nearbyDistanceThreshold <- 5;
    map<string, float> tastes;
    // this keeps track of which agents we've recently interacted with,
    // so we can avoid constantly high fiving someone near us, for example
	map<string, int> interactionMap <- [];
	// how many rounds to wait before we can interact with the same agent again
	int interactionResetLimit <- 100;
        
    rule belief: stage_location new_desire: tired strength: 2.0;
    rule belief: tired new_desire: chill strength: 3.0;
    rule belief: arrested new_desire: free strength: 100.0;
    
    // these personality traits are set in each sub-species,
    // and might impact choices the guests make when interacting
    // with eachother
    float sociability;
    float energyDensity;
    float spontaneity;
    
    bool listening <- false;
    float initial_fun <- 0.0;
    map<point, float> expected_reward;
    map<point, int> visits;
    
    // these are FIPA messages shared across different sub-species -
    // to avoid repetition, we place them here in the parent species
    // rather than hardcoding them in each sub-species
    string OFFER_DRINK <- "offer_drink"; // interaction between extrovert -> introvert
    
    init {
    	loop g over: genres {
    		tastes <- tastes + [g:: rnd(1.0)];
    	}
    	possible_stages <- get_beliefs_with_name(stage_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	
    	loop st over: possible_stages {
    		expected_reward <- expected_reward + [st:: 1000.0];
    		visits <- visits + [st:: 0];
    	}
    	do add_desire(find_stage);
    }
    
	list<introvert> introvertAgents <- agents of_species introvert;
	list<extrovert> extrovertAgents <- agents of_species extrovert;
	list<security> securityAgents <- agents of_species security;
	list<fighter> fighterAgents <- agents of_species fighter;
	list<addict> addictAgents <- agents of_species addict;
    
    reflex initAgents when: initialized = false
    {
    	list<festival_guest> guests <- agents of_generic_species festival_guest;
    	if (length(guests) != nb_guests) {
    		return;
    	}
		introvertAgents <- agents of_species introvert;
		extrovertAgents <- agents of_species extrovert;
		securityAgents <- agents of_species security;
		fighterAgents <- agents of_species fighter;
		addictAgents <- agents of_species addict;
		initialized <- true;
    }
    
    reflex incrementInteractionMap
    {
		loop i from: 0 to: length(agents) - 1
		{
			agent currentAgent <- agents at i;
			int currentVal <- interactionMap[currentAgent.name];
			if (currentVal >= 1) {
				int nextVal <- currentVal + 1;
				if debug = true 
				{
					write self.name + ": incrementing interaction map for: " + currentAgent.name + " to: " + nextVal;
				}
				if (nextVal > interactionResetLimit)
				{
					interactionMap[currentAgent.name] <- -1;
				} else {
					interactionMap[currentAgent.name] <- nextVal;	
				}
			}
			
		}
    }
    
    int getAgentIndex(string agentType)
	{
		if agentType = "introvert"
		{
			return 0;
		}
		if agentType = "extrovert"
		{
			return 1;
		}
		if agentType = "security"
		{
			return 2;
		}
		if agentType = "addict"
		{
			return 3;
		}
		if agentType = "fighter"
		{
			return 4;
		}
		int error <- 100/0;
	}
	
	action setAgentColor(string agentType)
	{
		if agentType = "introvert"
		{
			my_color <- #green;
		}
		else if agentType = "extrovert"
		{
			my_color <- #yellow;
		}
		else if agentType = "security"
		{
			my_color <- #orange;
		}
		else if agentType = "addict"
		{
			my_color <- #blue;
		}
		else if agentType = "fighter"
		{
			my_color <- #red;
		} 
		else {
			int error <- 100/0;	
		}
	}
	
    action go_chill
    {
        do add_belief(tired); 
       	target <- nil;
    }
    
    action go_jail 
    {
    	do add_belief(arrested);
    	target <- nil;
	}

    /**
     * This will return a list of nearby agents that the current agent has not interacted with
     * in recent time.
     */
    list<festival_guest> getNearbyAgentsOfType(list<festival_guest> agentsOfType)
    {
		list<festival_guest> nearbyGuests <- agentsOfType at_distance(nearbyDistanceThreshold);
		list<festival_guest> newNearbyGuests <- [];
    	if length(nearbyGuests) = 0
    	{
    		return [];
    	}
		loop i from: 0 to: length(nearbyGuests) - 1
		{
			festival_guest currentAgent <- nearbyGuests at i;
			if currentAgent.name = self.name 
			{
				// don't interact with self	
			} else if interactionMap[currentAgent.name] >= 1 {
				// avoid repeated interactions with same agents.
				// the map is incremented in a separate reflex
			} else {
				newNearbyGuests <- newNearbyGuests + currentAgent;
				interactionMap[currentAgent.name] <- 1;
			}
		}
		return newNearbyGuests;
    }
    
    perceive target: stage where (each.quality > 0) in: view_dist {
    	focus id: stage_at_location var: location;
    	ask myself {
	        do add_desire(predicate:share_information, strength: 5.0);
	        do remove_intention(find_stage, false);
	        
    	}    	
    }
    
    // This will determine the likeability of guests within view_dist,
    // NOTE: this is executed in the context of the other guest, not the
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

    plan lets_wander intention: find_stage {
    	fun <- fun + 1;
    	do wander;
    }
    
	plan listen_music intention: tired {

	    if (target = nil) {
	        do add_subintention(get_current_intention(),choose_stage, true);
	        do current_intention_on_hold();
	    } else {
	    	if listening = false {
				initial_fun <- fun;
				listening <- true;
				visits[target] <- visits[target] + 1;
			}
	        do goto target: target;
	        if (location distance_to(target) < 10)  {
		        stage current_stage <- stage first_with (target distance_to(each.location) < 10);
		        float appreciation <- tastes at current_stage.genre;
		        fun <- fun + current_stage.quality * appreciation;
		        tiredness <- tiredness + 1;
		        if (tiredness > 50) {
		        	if visits[target] > 1{
		        		expected_reward[target] <- expected_reward[target]/(visits[target]-1) + (fun - initial_fun)/visits[target];
		        	} else if  visits[target] = 1 {
		        		expected_reward[target] <- (fun - initial_fun)/visits[target];
		        	}
		        	do go_chill;
		        	listening <- false;
		        }
	        }
	    }   
	}
	/*
	plan choose_closest_stage intention: choose_stage instantaneous: true {
	    possible_stages <- get_beliefs_with_name(stage_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	    if (empty(possible_stages)) {
	        do remove_intention(tired, true); 
	    } else {
	        target <- (possible_stages with_min_of (each distance_to self)).location;
	    }
	    do remove_intention(choose_stage, true); 
    }
    */
    plan choose_best_stage intention: choose_stage instantaneous: true {
    	possible_stages <- get_beliefs_with_name(stage_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
    	map<point,float> choices <- find_choices(expected_reward);
    	target <- rnd_choice(choices);
    	do remove_intention(choose_stage, true);
    }
	
	map<point,float> find_choices(map<point, float> expected){
		map<point, float> choices;
		loop st over: possible_stages {
			if expected[st] > 0 {
				choices <- choices + [st:: expected[st]];
			} else {
				choices <- choices + [st:: 1000.0];
			}
		}
		return choices;
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
    
    plan go_to_jail intention: free {
    	do goto target: the_jail;
    	if (the_jail.location = location) {
    		sentence <- sentence - 1;
    		
    		if (sentence = 0){
	        	do remove_belief(arrested);
	        	do remove_intention(free, true);
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
	
	string SMALL_TALK <- "small_talk";
	
	init {
		sociability <- 0.1;
		energyDensity <- -0.5;
		spontaneity <- 0.2;
		agentIndex <- getAgentIndex("introvert");
		do setAgentColor("introvert");
	}
	
	action doSmallTalk
	{
		// introverts enjoy the company of each other,
		// so interacting with other introverts greatly
		// increases the level of fun they're having
		fun <- fun + 10;
	}
	
	action receiveDrink
	{
		// we don't always want to accept a drink from a stranger,
		// so use our spontaneity and sociability value to determine
		// if we should do so
		bool feelingSpontaneous <- rnd(1) <= spontaneity;
		if feelingSpontaneous
		{
			if debug = true
			{
				write self.name + ": accepting drink offer";
			}
			// even though introverts might feel spontaneous,
			// the increased fun isn't that significant
			// since they don't have a very high sociability value
			float increasedFun <- 10 * sociability;
			fun <- fun + increasedFun;
		} else {
			if debug = true
			{
				write self.name + ": rejecting drink offer";
			}
		}
	}
	
	reflex receiveInforms when: !empty(informs)
	{
		message receivedInform <- informs[0];
		list content <- receivedInform.contents;
		string messageType <- content[0];
		switch messageType
		{
			match SMALL_TALK
			{
				do doSmallTalk;
			}
			match OFFER_DRINK
			{
				do receiveDrink;
			}
			default
			{
				if debug = true
				{
					write self.name + ": unexpected inform received " + receivedInform;
				}
			}
		}
	}

	reflex smallTalk when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 1
	{
		list<introvert> introverts <- getNearbyAgentsOfType(introvertAgents) as list<introvert>;
		if length(introverts) > 0 {
			if debug = true
			{
				write self.name + ": small talking with nearby introverts: " + length(introverts);
			}
			do start_conversation (to :: introverts, protocol :: 'fipa-request', performative :: 'inform', contents :: [SMALL_TALK]);
		}
	}

	// TODO this should only be run while at a stage (intention = tried?)
	reflex avoid when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > avoidThreshold
	{
		list<extrovert> extroverts <- getNearbyAgentsOfType(extrovertAgents) as list<extrovert>;
		// TODO: don't run this when already in chill area?
		int nearbyExtroverts <- length(extroverts);
		if nearbyExtroverts > 0
		{
			if debug = true
			{
				write self.name + ": extroverts nearby are annoying, taking a break";
			}
			// reduce the fun we're having depending on the value
			// of our energy density personality trait
			bool feelingSpontaneous <- rnd(1) <= spontaneity;
			bool feelingSocial <- rnd(1) <= sociability;
			if !feelingSpontaneous and !feelingSocial
			{
				float reducedFun <- energyDensity * nearbyExtroverts;
				if fun > reducedFun {
					fun <- fun - reducedFun;
				}
				do go_chill;
			}
		}
	}
}

species extrovert parent: festival_guest {
	
	string OFFER_SHOTS <- "offer_shots";
	
	init {
		sociability <- 0.8;
		energyDensity <- 1.0;
		spontaneity <- 0.8;
		agentIndex <- getAgentIndex("extrovert");
		do setAgentColor("extrovert");
	}
	
	action receiveShots
	{
		// extroverts love being social, so receiveing shots
		// from likeminded individual greatly increases the fun
		// that they're having
		float sociabilityFun <- 5 * sociability;
		float spontaneityFun <- 5 * spontaneity;
		fun <- fun + sociabilityFun + spontaneityFun;
	}
	
	reflex receiveInforms when: !empty(informs)
	{
		message receivedInform <- informs[0];
		list content <- receivedInform.contents;
		string messageType <- content[0];
		switch messageType
		{
			match OFFER_SHOTS
			{
				do receiveShots;
			}
			default
			{
				if debug = true
				{
					write self.name + ": unexpected inform received " + receivedInform;
				}
			}
		}
	}

	reflex offerDrink when: length(introvertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		list<introvert> introverts <- getNearbyAgentsOfType(introvertAgents) as list<introvert>;

		if length(introverts) = 0
		{
			return;
		}
		
		if (rnd(1) > spontaneity) 
		{
			// don't always offer drinks, only do so spontaneously
			return;
		}

		if debug = true
		{
			write self.name + ": offering drink to nearby introverts: " + length(introverts);
		}

		do start_conversation (to :: introverts, protocol :: 'fipa-request', performative :: 'inform', contents :: [OFFER_DRINK]);
	}
	
	reflex offerShots when: length(extrovertAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		list<extrovert> extroverts <- getNearbyAgentsOfType(extrovertAgents) as list<extrovert>;

		if length(extroverts) = 0
		{
			return;
		}
		
		if (rnd(1) > spontaneity) 
		{
			// don't always offer shots, only do so spontaneously
			return;	
		}

		if debug = true
		{
			write self.name + ": offering shots to nearby extroverts: " + length(extroverts);
		}
		
		// since extroverts enjoy company, their fun is increased when they have likeminded individuals nearby
		fun <- fun + length(extroverts) * energyDensity;
		do start_conversation (to :: extroverts, protocol :: 'fipa-request', performative :: 'inform', contents :: [OFFER_SHOTS]);
	}
}

species fighter parent: festival_guest {
	
	init {
		sociability <- 0.2;
		energyDensity <- 0.3;
		spontaneity <- 0.1;
		agentIndex <- getAgentIndex("fighter");
		do setAgentColor("fighter");
	}
	
	reflex annoy when: length(securityAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		list<security> guards <- getNearbyAgentsOfType(securityAgents) as list<security>;
		
		if length(guards) = 0
		{
			return;
		}
		if debug = true
		{
			write self.name + ": annoying nearby security guards";
		}
		fun <- fun + 5;
		ask guards {
			if fun > 5 {
				fun <- fun - 5;
			}		
		}
	}	
	
	reflex fight when: length(addictAgents at_distance(nearbyDistanceThreshold)) > 0
	{
		list<addict> addicts <- getNearbyAgentsOfType(addictAgents) as list<addict>;
		
		if length(addicts) = 0
		{
			return;
		}
		if debug = true
		{
			write self.name + ": starting a fight with nearby addicts";			
		}
		fun <- fun + 5;
		ask addicts {
			if fun > 5 {
				fun <- fun - 5;
			}
		}	
	}
}

species security parent: festival_guest {
	
	init {
		sociability <- 0.2;
		energyDensity <- 0.8;
		spontaneity <- 0.1;
		agentIndex <- getAgentIndex("security");
		do setAgentColor("security");
	}
	
	reflex sendToJail when: length(addictAgents 	at_distance(nearbyDistanceThreshold)) > 0 or
							length(fighterAgents 	at_distance(nearbyDistanceThreshold)) > 0
	{
		list<addict> addicts <- getNearbyAgentsOfType(addictAgents) as list<addict>;
		list<fighter> fighters <- getNearbyAgentsOfType(fighterAgents) as list<fighter>;
		list<festival_guest> arrests <- addicts + fighters;
		if length(arrests) = 0
		{
			return;
		}
		if debug = true
		{
			write self.name + ": fighters or addicts nearby, arresting";
		}
		ask arrests {
			do go_jail;
			if fun > 0{
				fun <- fun/4*3;	
			}
			self.sentence <- rnd(10);
		}
	}
}

species addict parent: festival_guest {
	
	init {
		sociability <- -0.5;
		energyDensity <- 1.0;
		spontaneity <- 0.2;
		agentIndex <- getAgentIndex("addict");
		do setAgentColor("addict");
	}
	
	reflex avoid when: length(securityAgents 	at_distance(nearbyDistanceThreshold)) > 0 or
						length(fighterAgents 	at_distance(nearbyDistanceThreshold)) > 0
	{
		list<security> nearbySecurity <- getNearbyAgentsOfType(securityAgents) as list<security>;
		list<fighter> nearbyFighters <- getNearbyAgentsOfType(fighterAgents) as list<fighter>;
		
		list<festival_guest> avoids <- nearbySecurity + nearbyFighters;
		if length(avoids) > 0 
		{
			if debug = true
			{
				write self.name + ": fighters or guards nearby, avoiding them and taking a break";
			}
			if fun > 5 {
				fun <- fun - 5;
			}
			do go_chill;
		}
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
	        species lounge;
	        species stage;
	        species jail;
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