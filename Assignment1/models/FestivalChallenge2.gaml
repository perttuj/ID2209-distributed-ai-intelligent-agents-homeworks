/**
* Name: FestivalChallenge2
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model FestivalChallenge2

global {
	int numberOfPeople <- 20;
	
	int numberOfFoodStores <- 3;
	int numberOfDrinkStores <- 3;
	int numberOfDrinkFoodStores <- 3;
	
	int numberOfInfoCenter <- 1;
	
	int distanceThreshold <- 10;
	
	point informationCenterLocation <- {50,50};
	
	/** START NEW PART - CHALLENGE 2 */
	int numberOfBadPeople <- 5;
	int numberOfSecurity <- 1;
	/** END NEW PART - CHALLENGE 2 */
	
	init {
		create FestivalGuest number: numberOfPeople;
		create DrinkStore number: numberOfDrinkStores;
		create FoodStore number: numberOfFoodStores;
		create DrinkFoodStore number: numberOfDrinkFoodStores;
		create InformationCenter number: numberOfInfoCenter
		{
			location <- informationCenterLocation;
		}
		/** START NEW PART - CHALLENGE 2 */
		create FestivalGuest number: numberOfBadPeople
		{
			isBad <- true;
			color <- #black;
		}
		create SecurityGuard number: numberOfSecurity;
		/** END NEW PART - CHALLENGE 2 */
	}
}

species FestivalGuest skills:[moving]
{
	int THIRST <- 100000 update: THIRST - rnd(100);
	int HUNGER <- 100000 update: HUNGER - rnd(100);
	int traversalPrintThreshold <- 10;
	
	point targetPoint <- nil;
	
	float size <- 1.0;
	rgb color <- #blue;
	
	int traversedSteps <- 0;
	list<int> traversedStepsHistory;
	list<point> memoDrink;
	list<point> memoFood;
	list<point> memoDrinkFood;

	/** START NEW PART - CHALLENGE 2
	 * This specifies if the agent in question
	 * is behaving badly or not */
	bool isBad <- false;
	/** END NEW PART - CHALLENGE 2 */
	
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}

	reflex moveToTarget when: targetPoint != nil
	{
		traversedSteps <- traversedSteps + 1;
		do goto target:targetPoint;
	}
	
	reflex enterStore when: targetPoint != nil and location distance_to(targetPoint)<2
	{
		traversedStepsHistory <- traversedStepsHistory + traversedSteps;
		int historyLength <- length(traversedStepsHistory);
		if (historyLength mod traversalPrintThreshold = 0)
		{
			int totalSteps <- 0;
			// we want to occasionally print out what the average steps taken is for guests
			loop i from: 0 to: historyLength - 1
			{
				totalSteps <- totalSteps + traversedStepsHistory at i;
			}
			write "average steps taken by guest: " + totalSteps / historyLength;
		}
		// Replenish everything the store has to offer.
		// we want to avoid multiple trips if possible!
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
		traversedSteps <- 0;
		color <- #blue;
	}

	reflex imHungryOrThirsty when: (THIRST < 3 or HUNGER < 3) and targetPoint = nil
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
		if flip(0.5){
			do goto target:informationCenterLocation;
			return;
		}
		if isThirsty {
			if !empty(memoDrink){
				int idx <- rnd(length(memoDrink) - 1);
				targetPoint <- memoDrink at idx;
			} else {
				do goto target:informationCenterLocation;
			}
			
		}
		if isHungry {
			if !empty(memoFood){
				int idx <- rnd(length(memoFood) - 1);
				targetPoint <- memoFood at idx;
			} else {
				do goto target:informationCenterLocation;
			}
			
		}
		if isHungryAndThirsty {
			if !empty(memoDrinkFood){
				int idx <- rnd(length(memoDrinkFood) - 1);
				targetPoint <- memoDrinkFood at idx;
			} else {
				do goto target:informationCenterLocation;
			}
		}
	}

	reflex getDirections when: location distance_to(informationCenterLocation)<2 and (THIRST < 3 or HUNGER < 3)
	{
		bool isThirsty <- THIRST < 3 and HUNGER >= 3;
		bool isHungry <- THIRST >= 3 and HUNGER < 3;
		bool isHungryAndThirsty <- THIRST < 3 and HUNGER < 3;
	
		if isThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkStoreLocations[rnd(numberOfDrinkStores-1)].location;
			}

			if !(memoDrink contains targetPoint) {
				memoDrink <- memoDrink + targetPoint;
			}
		}
		if isHungry {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.foodStoreLocations[rnd(numberOfFoodStores-1)].location;
			}

			if !(memoFood contains targetPoint) {
				memoFood <- memoFood + targetPoint;
			}
		}
		if isHungryAndThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkFoodStoreLocations[rnd(numberOfDrinkFoodStores-1)].location;
			}

			if !(memoDrinkFood contains targetPoint) {
				memoDrinkFood <- memoDrinkFood + targetPoint;
			}
		}
	}
	
	aspect base
	{
		draw square(size) color: color;
	}
}

/** START NEW PART - CHALLENGE 2
 * Here we specify the species of our Security Guard,
 * who will kill people without mercy (such is life, I guess)
 */
species SecurityGuard skills: [moving]
{
	float size <- 2.0;
	rgb color <- #purple;
	
	FestivalGuest targetAgent <- nil;
	
	reflex when: targetAgent = nil
	{
		do wander;
	}
	
	reflex when: targetAgent != nil and location distance_to(targetAgent) > 2
	{
		// update location to target to make sure we're following them. they cannot escape!
		ask targetAgent {
			myself.targetAgent <- self;
		}
		do goto target: targetAgent;
	}
	
	reflex when: targetAgent != nil and location distance_to(targetAgent) <= 2
	{
		write "i'm sorry little one";
		ask targetAgent {
			do die;
		}
		// next target, please!
		targetAgent <- nil;
	}

	aspect base
	{
		draw square(size) color: color;
	}
}
/** END NEW PART - CHALLENGE 2 */

species InformationCenter
{
	list<DrinkStore> drinkStoreLocations <- (DrinkStore at_distance 1000);
	list<FoodStore> foodStoreLocations <- (FoodStore at_distance 1000);
	list<DrinkFoodStore> drinkFoodStoreLocations <- (DrinkFoodStore at_distance 1000);

	float size <- 1.0;
	rgb color <- #green;
	
	/** START NEW PART - CHALLENGE 2
	 * We need to keep track of any bad agents
	 * that come near the store, and phone
	 * the security guard as fast as possible!
	 */
	FestivalGuest badAgent <- nil;
	
	reflex anyBadAgents
	{
		// check what agents are near us
		list<FestivalGuest> neighbors <- agents of_species FestivalGuest at_distance(5);
		if length(neighbors) > 0 
		{
			loop i from: 0 to: length(neighbors) - 1
			{
				FestivalGuest currentAgent <- neighbors at i;
				// check if any of our neighbours are behaving badly!
				ask currentAgent {
					if self.isBad {
						myself.badAgent <- self;
					}
				}
			}
		}
	}
	
	reflex notifyGuard when: badAgent != nil
	{
		// notify the closest guard. Please kill this guy!
		SecurityGuard guard <- SecurityGuard closest_to(self);
		ask guard {
			// make sure we aren't distracted by multiple bad agents
			// we kill one at a time!
			if self.targetAgent != nil
			{
				self.targetAgent <- myself.badAgent;
			}
		}
		badAgent <- nil;
	}
	/** END NEW PART - CHALLENGE 2 */
	
	aspect base
	{
		draw circle(size) color: color;
	}
}

species Store
{
	bool sellsDrink <- false;
	bool sellsFood <- false;
	float size <- 1.0;
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

experiment festival type: gui {
	
	output {
		display main_display {
			species FestivalGuest aspect: base;
			species FoodStore aspect: base;
			species DrinkStore aspect: base;
			species DrinkFoodStore aspect: base;
			species InformationCenter aspect: base;
			/** START NEW PART - CHALLENGE 2 */
			species SecurityGuard aspect: base;
			/** END NEW PART - CHALLENGE 2 */
		}
	}
}