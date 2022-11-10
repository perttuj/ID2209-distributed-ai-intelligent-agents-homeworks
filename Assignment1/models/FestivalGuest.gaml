model FestivalGuest

global {
	int numberOfPeople <- 300;
	
	int numberOfFoodStores <- 3;
	int numberOfDrinkStores <- 3;
	int numberOfDrinkFoodStores <- 3;
	
	int numberOfInfoCenter <- 1;
	
	int distanceThreshold <- 10;
	
	point informationCenterLocation <- {50,50};
	
	init {
		create FestivalGuest number: numberOfPeople;
		
		create drinkStore number: numberOfDrinkStores;
		create foodStore number: numberOfFoodStores;
		create drinkFoodStore number: numberOfDrinkFoodStores;
		
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
	
	point targetPoint <- nil;
	
	list<point> memoDrink;
	list<point> memoFood;
	list<point> memoDrinkFood;

	
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
		THIRST <- 100000;
		HUNGER <- 100000;
		targetPoint <- nil;
	}
	
	reflex imHungryOrThirsty when: (THIRST < 3 or HUNGER < 3) and targetPoint = nil
	{
		write memoDrinkFood;
		if flip(0.5){
			if THIRST < 3 and HUNGER >= 3 {
				if !empty(memoDrink){
					targetPoint <- 1 among memoDrink;
				} else {
					do goto target:informationCenterLocation;
				}
				
			}
			if THIRST >= 3 and HUNGER < 3 {
				
				if !empty(memoFood){
					targetPoint <- 1 among memoFood;
				} else {
					do goto target:informationCenterLocation;
				}
				
			}
			if THIRST < 3 and HUNGER < 3 {
				
				if !empty(memoDrinkFood){
					targetPoint <-  1 among memoDrinkFood;
				} else {
					do goto target:informationCenterLocation;
				}
			}
		} else {
			do goto target:informationCenterLocation;
		}
	}
	
	reflex getDirections when: location distance_to(informationCenterLocation)<2 and (THIRST < 3 or HUNGER < 3)
	{
		if THIRST < 3 and HUNGER >= 3 {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkStoreLocations[rnd(numberOfDrinkStores-1)].location;
			}
			if !(memoDrink contains targetPoint) {
				memoDrink <- memoDrink + targetPoint;
			}
		}
		if THIRST >= 3 and HUNGER < 3 {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.foodStoreLocations[rnd(numberOfFoodStores-1)].location;
			}
			if !(memoFood contains targetPoint) {
				memoFood <- memoFood + targetPoint;
			}
		}
		if THIRST < 3 and HUNGER < 3 {
			ask InformationCenter at_distance(distanceThreshold) {
				myself.targetPoint <- self.drinkFoodStoreLocations[rnd(numberOfDrinkFoodStores-1)].location;
			}
			if !(memoDrinkFood contains targetPoint) {
				memoDrinkFood <- memoDrinkFood + targetPoint;
			}
		}
	}
	
	float size <- 1.0;
	rgb color <- #blue;
	
	aspect base
	{
		draw square(size) color: color;
	}
}

species InformationCenter
{
		
	list<drinkStore> drinkStoreLocations <- (drinkStore at_distance 1000);
	list<foodStore> foodStoreLocations <- (foodStore at_distance 1000);
	list<drinkFoodStore> drinkFoodStoreLocations <- (drinkFoodStore at_distance 1000);

	
	float size <- 1.0;
	rgb color <- #green;
	
	aspect base
	{
		draw circle(size) color: color;
	}
}

species Store
{

}

species foodStore parent: Store
{
	float size <- 1.0;
	rgb color <- #red;
	
	aspect base
	{
		draw triangle(size) color: color;
	}
}

species drinkStore parent: Store
{
	float size <- 1.0;
	rgb color <- #yellow;
	
	aspect base
	{
		draw triangle(size) color: color;
	}
}

species drinkFoodStore parent: Store
{
	float size <- 1.0;
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
			species foodStore aspect: base;
			species drinkStore aspect: base;
			species drinkFoodStore aspect: base;
			species InformationCenter aspect: base;

		}
	}
}