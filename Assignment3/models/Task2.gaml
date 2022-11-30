/**
* Name: NQueens
* Based on the internal empty template. 
* Author: perttuj & GGMorello
* Tags: 
*/

model Task2

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
		create FestivalGuest number: numberOfPeople
		{
			// TODO assing random utility
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
	
	Stage currentStage <- nil;
	list<Stage> stages <- agents of_species Stage;
	
	float size <- 1.0;
	rgb color <- #blue;
	
	float bandRatio <- 0.0;
	float dancersRatio <- 0.0;
	float lightShowRatio <- 0.0;
	float soundRatio <- 0.0;
	float stagePresenceRatio <- 0.0;
	float vfxRatio <- 0.0;
	
	init {
		bandRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		dancersRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		lightShowRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		soundRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		stagePresenceRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		vfxRatio <- rnd(0, initRatioMaxValue) with_precision ratioPrecision;
		list<float> ratioValues <- [bandRatio, dancersRatio, lightShowRatio, soundRatio, stagePresenceRatio, vfxRatio];
		if (debug = true) {
			write self.name + ": ratio values order = band, dancers, lightshow, sound, stage, vfx";
			write self.name + ": ratio values = " + ratioValues;
		}
		do calculateBestStage;
	}
	
	float calculateStageUtility(Stage s) {
		float bandValue <- bandRatio * s.bandRatio with_precision ratioPrecision;
		float dancersValue <- dancersRatio * s.dancersRatio with_precision ratioPrecision;
		float lightsValue <- lightShowRatio * s.lightShowRatio with_precision ratioPrecision;
		float soundValue <- soundRatio * s.soundRatio with_precision ratioPrecision;
		float stageValue <- stagePresenceRatio * s.stagePresenceRatio with_precision ratioPrecision;
		float vfxValue <- vfxRatio * s.vfxRatio with_precision ratioPrecision;
		list<float> ratioValues <- [bandValue, dancersValue, lightsValue, soundValue, stageValue, vfxValue];
		float allValuesSum <- sum(ratioValues);
		if debug = true {
			write self.name + ": ratio for stage " + s.name + ", ratio values order = band, dancers, lightshow, sound, stage, vfx";
			write self.name + ": stage ratio values = " + ratioValues + ", sum: " + allValuesSum;
		}
		return allValuesSum;
	}
	
	action calculateBestStage
	{
		Stage maxStage <- nil;
		float currentMax <- 0.0;
		loop i from: 0 to: length(stages) - 1 {
			Stage s <- stages at i;
			float stageUtil <- calculateStageUtility(s);
			if maxStage = nil or currentMax < stageUtil
			{
				maxStage <- s;
				currentMax <- stageUtil;
			}
		}
		if debug = true {
			write self.name + ": best stage: " + maxStage.name + ", util: " + currentMax;
			write "";
		}
		
		currentStage <- maxStage;
	}
	
	reflex beIdle when: targetPoint = nil
	{
		do wander;
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
		color <- #blue;
	}

	reflex headTowardInformationCenter when: headingToInfoCenter = true
	{
		// IS THIS MISSING?: traversedSteps <- traversedSteps + 1;
		do goto target: informationCenterLocation;
	}

	reflex imHungryOrThirsty when: (THIRST < 3 or HUNGER < 3) and targetPoint = nil and headingToInfoCenter = false
	{
		bool isThirsty <- THIRST < 3 and HUNGER >= 3;
		bool isHungry <- THIRST >= 3 and HUNGER < 3;
		bool isHungryAndThirsty <- THIRST < 3 and HUNGER < 3;

		if isThirsty
		{
			color <- #yellow;
		} 
		else if isHungry
		{
			color <- #red;
		}
		else if isHungryAndThirsty
		{
			color <- #orange;
		}

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
		string content <- receivedInform.contents[0];
		// TODO handle content
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

species Stage {
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
	}
	
	
	reflex idleStage
	{
		list<FestivalGuest> guests <- agents of_species FestivalGuest;
		// occasionally rotate the current concert
		// so that guests have to change stages
		if (flip(0.001))
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