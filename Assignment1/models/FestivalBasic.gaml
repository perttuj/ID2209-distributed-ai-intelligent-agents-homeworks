/**
* Name: FestivalBasic
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model FestivalBasic

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
	
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}

	reflex moveToTarget when: targetPoint != nil
	{
		// TODO: Combine this with enterStore?
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
		// TODO: Replenish either thirst or hunger, not both
		THIRST <- 100000;
		HUNGER <- 100000;
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

		do goto target:informationCenterLocation;
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
		}
		if isHungry {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.foodStoreLocations[rnd(numberOfFoodStores-1)].location;
			}
		}
		if isHungryAndThirsty {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkFoodStoreLocations[rnd(numberOfDrinkFoodStores-1)].location;
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
	float size <- 1.0;

}

species FoodStore parent: Store
{
	rgb color <- #red;
	
	aspect base
	{
		draw triangle(size) color: color;
	}
}

species DrinkStore parent: Store
{
	rgb color <- #yellow;
	
	aspect base
	{
		draw triangle(size) color: color;
	}
}

species DrinkFoodStore parent: Store
{
	rgb color <- #orange;
	
	aspect base
	{
		draw triangle(size) color: color;
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