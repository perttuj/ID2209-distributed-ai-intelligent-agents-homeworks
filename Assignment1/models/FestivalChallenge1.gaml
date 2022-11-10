/**
* Name: FestivalChallenge1
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model FestivalChallenge1

global {
	int numberOfPeople <- 20;
	
	int numberOfFoodStores <- 3;
	int numberOfDrinkStores <- 3;
	int numberOfDrinkFoodStores <- 3;
	
	int numberOfInfoCenter <- 1;
	
	int distanceThreshold <- 10;
	
	point informationCenterLocation <- {50,50};
	
	init {
		create FestivalGuest number: numberOfPeople;
		create DrinkStore number: numberOfDrinkStores;
		create FoodStore number: numberOfFoodStores;
		create DrinkFoodStore number: numberOfDrinkFoodStores;
		create InformationCenter number: numberOfInfoCenter
		{
			location <- informationCenterLocation;
		}
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

	/** START NEW PART - CHALLENGE 1
	 * Here, we define the shape of our "brain" */
	list<point> memoDrink;
	list<point> memoFood;
	list<point> memoDrinkFood;
	/** END NEW PART - CHALLENGE 1 */

	
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
		/** START NEW PART - CHALLENGE 1
		 * Here, we want to "look in our brain" to see
		 * if we already know some route to a store.
		 * In some cases, we want to explore anyway -
		 * so we've set the probability to 50% here.
		 */
		if flip(0.5){
			// explore a new store
			do goto target:informationCenterLocation;
			return;
		}
		// else, "look in our brain" for a known location (if there is any..)!
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
		/** END NEW PART - CHALLENGE 1 */
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

			/** START NEW PART - CHALLENGE 1 */
			if !(memoDrink contains targetPoint) {
				memoDrink <- memoDrink + targetPoint;
			}
			/** END NEW PART - CHALLENGE 1 */
		}
		if isHungry {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.foodStoreLocations[rnd(numberOfFoodStores-1)].location;
			}

			/** START NEW PART - CHALLENGE 1 */
			if !(memoFood contains targetPoint) {
				memoFood <- memoFood + targetPoint;
			}
			/** START NEW PART - CHALLENGE 1 */
		}
		if isHungryAndThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkFoodStoreLocations[rnd(numberOfDrinkFoodStores-1)].location;
			}

			/** START NEW PART - CHALLENGE 1 */
			if !(memoDrinkFood contains targetPoint) {
				memoDrinkFood <- memoDrinkFood + targetPoint;
			}
			/** START NEW PART - CHALLENGE 1 */
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
		}
	}
}