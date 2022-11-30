/**
* Name: GlobalUtility
* Based on the internal empty template. 
* Author: perttuj & GGMorello
* Tags: 
*/

model GlobalUtility

global {
	int numberOfPeople <- 21;
	
	int numberOfFoodStores <- 2;
	int numberOfDrinkStores <- 2;
	int numberOfDrinkFoodStores <- 2;
	
	int numberOfInfoCenter <- 1;
	
	bool debug <- true;
	
	int distanceThreshold <- 10;
	
	point informationCenterLocation <- {50,75};
	
	float initRatioMaxValue <- 1.0;
	int ratioPrecision <- 4;

	rgb bandColor <- #black;
	rgb dancersColor <- #red;
	rgb lightShowColor <- #yellow;
	rgb soundColor <- #green;
	rgb stagePresenceColor <- #orange;
	rgb vfxColor <- #pink;
	
	string START_COORDINATION <- "start_coordination";
	string COORDINATION_CFP <- "coordination_cfp";
	string ROTATE_STAGE <- "rotate_stage";
	
	init {
		create Stage number: 1
		{
			location <- {20, 0};
		}
		create Stage number: 1
		{
			location <- {45, 0};
		}
		create Stage number: 1
		{
			location <- {70, 0};
		}
		create Stage number: 1
		{
			location <- {95, 0};
		}
		create FestivalGuest number: 2*numberOfPeople / 3
		{
			densityRatio <- 0.9;
		}
		create FestivalGuest number: numberOfPeople / 3
		{
			densityRatio <- 0.1;
		}

		create FoodStore number: 1
		{
			location <- {0,25};
		}
		create DrinkStore number: 1
		{
			location <- {20,25};
		}
		create DrinkFoodStore number: 1
		{
			location <- {40,25};
		}
		create FoodStore number: 1
		{
			location <- {60,25};
		}
		create DrinkStore number: 1
		{
			location <- {80,25};
		}
		create DrinkFoodStore number: 1
		{
			location <- {100,25};
		}
		create InformationCenter number: numberOfInfoCenter
		{
			location <- informationCenterLocation;
		}
	}
}

species FestivalGuest skills:[moving, fipa]
{
	int THIRST <- 100000 update: THIRST - rnd(100);
	int HUNGER <- 100000 update: HUNGER - rnd(100);
	
	point targetPoint <- nil;
	bool headingToInfoCenter <- false;
	list<point> memoDrink;
	list<point> memoFood;
	list<point> memoDrinkFood;
	
	bool isLeader <- false;
	Stage currentStage <- nil;
	list<Stage> stages <- agents of_species Stage;
	list<FestivalGuest> guests <- agents of_species FestivalGuest;
	
	float size <- 1.0;
	rgb color <- #blue;
	
	float bandRatio <- 0.0;
	float dancersRatio <- 0.0;
	float lightShowRatio <- 0.0;
	float soundRatio <- 0.0;
	float stagePresenceRatio <- 0.0;
	float vfxRatio <- 0.0;
	float densityRatio <- 0.0;
	
	init {
		bandRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		dancersRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		lightShowRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		soundRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		stagePresenceRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		vfxRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		list<float> ratioValues <- [bandRatio, dancersRatio, lightShowRatio, soundRatio, stagePresenceRatio, vfxRatio, densityRatio];
		if (debug = true) {
			write self.name + ": ratio values order = band, dancers, lightshow, sound, stage, vfx, density";
			write self.name + ": ratio values = " + ratioValues;
		}
		if name = "FestivalGuest0"
		{
			write self.name + ": is leader";
			isLeader <- true;
		}
	}
	
	float calculateStageUtility(Stage s, int density) {
		float bandValue <- bandRatio * s.bandRatio with_precision ratioPrecision;
		float dancersValue <- dancersRatio * s.dancersRatio with_precision ratioPrecision;
		float lightsValue <- lightShowRatio * s.lightShowRatio with_precision ratioPrecision;
		float soundValue <- soundRatio * s.soundRatio with_precision ratioPrecision;
		float stageValue <- stagePresenceRatio * s.stagePresenceRatio with_precision ratioPrecision;
		float vfxValue <- vfxRatio * s.vfxRatio with_precision ratioPrecision;
		float densityValue <- densityRatio * density with_precision ratioPrecision;
		list<float> ratioValues <- [bandValue, dancersValue, lightsValue, soundValue, stageValue, vfxValue];
		float allValuesSum <- sum(ratioValues);
		if debug = true {
			// write self.name + ": ratio values order = band, dancers, lightshow, sound, stage, vfx";
			// write self.name + ": stage " + s.name + " ratio values = " + ratioValues + ", sum: " + allValuesSum;
		}
		return allValuesSum;
	}
	
	action calculateBestStages(list<int> densities)
	{
		list stageUtils <- [];
		// Stage maxStage <- nil;
		// float currentMax <- 0.0;
		loop i from: 0 to: length(stages) - 1 {
			Stage s <- stages at i;
			float stageUtil <- 0.0;
			if (length(densities) > 0) {
				stageUtil <- calculateStageUtility(s, densities[i]);
			} else {
				stageUtil <- calculateStageUtility(s, 0);
			}
			stageUtils <- stageUtils + stageUtil;
			/* 
			if maxStage = nil or currentMax < stageUtil
			{
				maxStage <- s;
				currentMax <- stageUtil;
			}*/
		}
		/* 
		if debug = true {
			write self.name + ": new best stage: " + maxStage.name + ", util: " + currentMax;
		}*/
		return stageUtils;
	}
	
	action handleInitialCfp(message msg)
	{
		list<int> densities <- [];
		list<float> stageUtils <- calculateBestStages(densities);
		do propose message: msg contents: [stageUtils];
	}
	
	action handleStageCfp(message msg)
	{
		list<int> stageDensities <- msg.contents[1];
		list<float> stageUtils <- calculateBestStages(stageDensities);
		do propose message: msg contents: [stageUtils];
	}
	
	reflex beIdle when: targetPoint = nil
	{
		if headingToInfoCenter = true 
		{
			do goto target: informationCenterLocation;
		}
		else if currentStage != nil
		{
			if location distance_to(currentStage) < 10
			{
				do wander;
			}
			else 
			{
				do goto target: currentStage;	
			}
		} 
		else 
		{
			do wander;	
		}
	}

	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
	}
	
	reflex enterStore when: targetPoint != nil and location distance_to(targetPoint)<2
	{
		ask agents of_generic_species Store closest_to(location)
		{
			if self.sellsDrink
			{
				myself.THIRST <- 100000;
			}
			if self.sellsFood
			{
				myself.HUNGER <- 100000;
			}
		}
		targetPoint <- nil;
	}

	reflex imHungryOrThirsty when: (THIRST < 3 or HUNGER < 3) and targetPoint = nil and headingToInfoCenter = false
	{
		bool isThirsty <- THIRST < 3 and HUNGER >= 3;
		bool isHungry <- THIRST >= 3 and HUNGER < 3;
		bool isHungryAndThirsty <- THIRST < 3 and HUNGER < 3;

		if flip(0.8) {
			if isHungryAndThirsty {
				if !empty(memoDrinkFood){
					int idx <- rnd(length(memoDrinkFood) - 1);
					targetPoint <- memoDrinkFood at idx;
				} else {
					headingToInfoCenter <- true;
				}
			}
			else if isThirsty {
				if !empty(memoDrink){
					int idx <- rnd(length(memoDrink) - 1);
					targetPoint <- memoDrink at idx;
				} else {
					headingToInfoCenter <- true;
				}
			}
			else if isHungry {
				if !empty(memoFood){
					int idx <- rnd(length(memoFood) - 1);
					targetPoint <- memoFood at idx;
				} else {
					headingToInfoCenter <- true;
				}
			}
		} else {
			headingToInfoCenter <- true;
		}
	}

	reflex getDirections when: headingToInfoCenter = true and location distance_to(informationCenterLocation) < 2 and (THIRST < 3 or HUNGER < 3) and targetPoint = nil
	{
		bool isThirsty <- THIRST < 3 and HUNGER >= 3;
		bool isHungry <- THIRST >= 3 and HUNGER < 3;
		bool isHungryAndThirsty <- THIRST < 3 and HUNGER < 3;
		
		headingToInfoCenter <- false;

		if isHungryAndThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkFoodStoreLocations[rnd(numberOfDrinkFoodStores-1)].location;
			}

			if !(memoDrinkFood contains targetPoint) {
				memoDrinkFood <- memoDrinkFood + targetPoint;
			}
			if !(memoDrink contains targetPoint) {
				memoDrink <- memoDrink + targetPoint;
			}
			if !(memoFood contains targetPoint) {
				memoFood <- memoFood + targetPoint;
			}
		}
		else if isThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkStoreLocations[rnd(numberOfDrinkStores-1)].location;
			}

			if !(memoDrink contains targetPoint) {
				memoDrink <- memoDrink + targetPoint;
			}
		}
		else if isHungry {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.foodStoreLocations[rnd(numberOfFoodStores-1)].location;
			}
			if !(memoFood contains targetPoint) {
				memoFood <- memoFood + targetPoint;
			}
		}
	}
	
	reflex receiveInforms when: (!empty(informs))
	{
		message receivedInform <- informs[0];
		list content <- receivedInform.contents;
		string messageType <- content[0];
		switch messageType
		{
			match ROTATE_STAGE
			{
				// when some stage rotates, the leader will
				// initialize a new election to determine
				// which guests go to which stage
				if isLeader = true
				{
					do start_conversation (to :: guests, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [START_COORDINATION]);
				}
			}
		}
	}
	
	reflex receiveProposals when: !empty(proposes)
	{
		// TODO read proposals and do a new iteratio of negotiation
		list<int> densities <- [];
		do start_conversation (to :: guests, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [COORDINATION_CFP, densities]);
	}
	
	reflex receiveCfp when: !empty(cfps)
	{
		message receivedCfp <- cfps[0];
		list content <- receivedCfp.contents;
		string cfpType <- content[0];
		switch cfpType
		{
			match START_COORDINATION
			{
				do handleInitialCfp(receivedCfp);
			}
			match COORDINATION_CFP
			{
				do handleStageCfp(receivedCfp);
			}
		}
	}
	
	aspect base
	{
		draw square(size) color: color;
	}
}

species InformationCenter
{
	list<DrinkStore> drinkStoreLocations <- (DrinkStore at_distance 1000);
	list<FoodStore> foodStoreLocations <- (FoodStore at_distance 1000);
	list<DrinkFoodStore> drinkFoodStoreLocations <- (DrinkFoodStore at_distance 1000);

	float size <- 1.0;
	rgb color <- #green;
	
	aspect base
	{
		draw circle(size) color: color;
	}
}

species Store
{
	bool sellsDrink <- false;
	bool sellsFood <- false;
	float size <- 2.0;
	rgb color;
	
	aspect base
	{
		draw triangle(size) color: color;
	}
}

species FoodStore parent: Store
{
	init {
		sellsFood <- true;
		color <- #red;
	}
}

species DrinkStore parent: Store
{
	init {
		sellsDrink <- true;
		color <- #yellow;
	}
}

species DrinkFoodStore parent: Store
{	
	init {
		sellsDrink <- true;
		sellsFood <- true;
		color <- #orange;
	}
}

species Stage skills: [fipa] {
	float bandRatio <- 0.0;
	float dancersRatio <- 0.0;
	float lightShowRatio <- 0.0;
	float soundRatio <- 0.0;
	float stagePresenceRatio <- 0.0;
	float vfxRatio <- 0.0;

	float size <- 5.0;
	rgb color <- #green;
	
	init {
		do rotateConcert;
	}
	
	action rotateConcert
	{
		bandRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		dancersRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		lightShowRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		soundRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		stagePresenceRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		vfxRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		list<float> ratioValues <- [bandRatio, dancersRatio, lightShowRatio, soundRatio, stagePresenceRatio, vfxRatio];
		float max <- max(ratioValues);
		if (debug = true) {
			write self.name + ": ratio values order = band, dancers, lightshow, sound, stage, vfx";
			write self.name + ": ratio values = " + ratioValues;
		}
		switch(max)
		{
			match bandRatio {
				if debug = true {
					write self.name + ": max ratio is band: " + max;
				}
				color <- bandColor;
			}
			match dancersRatio {
				if debug = true {
					write self.name + ": max ratio is dancers: " + max;
				}
				color <- dancersColor;
			}
			match lightShowRatio {
				if debug = true {
					write self.name + ": max ratio is light show: " + max;
				}
				color <- lightShowColor;
			}
			match soundRatio {
				if debug = true {
					write self.name + ": max ratio is sound: " + max;
				}
				color <- soundColor;
			}
			match stagePresenceRatio {
				if debug = true {
					write self.name + ": max ratio is stage: " + max;
				}
				color <- stagePresenceColor;
			}
			match vfxRatio {
				if debug = true {
					write self.name + ": max ratio is vfx: " + max;
				}
				color <- vfxColor;
			}
		}
		list<FestivalGuest> allGuests <- agents of_species FestivalGuest;
		// we might not yet have any guests at the festival
		if length(allGuests) > 0
		{
			do start_conversation (to :: allGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: [ROTATE_STAGE, self]);	
		}
	}
	
	reflex idleStage
	{
		list<FestivalGuest> guests <- agents of_species FestivalGuest;
		// occasionally rotate the current concert
		// so that guests have to change stages
		if (flip(0.0001))
		{
			if (debug = true) {
				write self.name + ": rotating to new concert ";
			}
			do rotateConcert;
		}
	}
	
	aspect base
	{
		draw rectangle(size*2, size) color: color;
	}
	
}

experiment festival type: gui {
	output {
		display main_display {
			species FestivalGuest aspect: base;
			species FoodStore aspect: base;
			species DrinkStore aspect: base;
			species DrinkFoodStore aspect: base;
			species InformationCenter aspect: base;
			species Stage aspect: base;
		}
	}
}