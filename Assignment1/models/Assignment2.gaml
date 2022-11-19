/**
* Name: FestivalChallenge2
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model FestivalChallenge2

global {
	int numberOfPeople <- 20;
	
	int numberOfFoodStores <- 2;
	int numberOfDrinkStores <- 2;
	int numberOfDrinkFoodStores <- 2;
	
	int numberOfInfoCenter <- 1;
	
	int distanceThreshold <- 10;
	
	int numberOfSecurity <- 1;
	
	
	point informationCenterLocation <- {50,75};
	
	point auctionLocation <- {50, 50};
	
	
	init {
		create FestivalGuest number: numberOfPeople;

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
		create SecurityGuard number: numberOfSecurity;
		
		create Initiator
		{
			location <- auctionLocation;
		}
	}
}

species FestivalGuest skills:[moving, fipa]
{
	int THIRST <- 100000 update: THIRST - rnd(100);
	int HUNGER <- 100000 update: HUNGER - rnd(100);
	
	point targetPoint <- nil;
	
	float size <- 1.0;
	rgb color <- #blue;
	
	int traversedSteps <- 0;
	int traversalPrintThreshold <- 10;
	list<int> traversedStepsHistory;

	bool headingToInfoCenter <- false;
	list<point> memoDrink;
	list<point> memoFood;
	list<point> memoDrinkFood;

	bool isBad <- false;
	
	
	bool joinAuction <- false;
	
	int money <- rnd(1000, 10000);
	
	
	reflex beIdle when: targetPoint = nil
	{
		do wander;

		if (flip(0.001)) {
			isBad <- true;
			color <- #black;
		}
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
			loop i from: 0 to: historyLength - 1
			{
				totalSteps <- totalSteps + traversedStepsHistory at i;
			}
			traversedStepsHistory <- [];
		}
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
		if self.isBad 
		{
			color <- #black;
		} 
		else {
			color <- #blue;
		}
	}

	reflex headTowardInformationCenter when: headingToInfoCenter = true
	{
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
	
	reflex answerInvitation when: (!empty(informs))
	{
		if THIRST > 10000 and HUNGER > 10000 and money > 0 {
			message requestFromInitiator <- (requests at 0);
			do agree with: (message: requestFromInitiator, contents: ['I will']);
			joinAuction <- true;
		} else {
			message requestFromInitiator <- (requests at 0);
			do refuse with: (message: requestFromInitiator, contents: ['I won\'t']);
		}
	}
	
	reflex gotoAuction when: joinAuction = true
	{
		do goto target: auctionLocation;
	}
	
	reflex auction when: (!empty(cfps)) {
		message cfp <- cfps at 0;
		int price <- cfp.contents at 1;
		if price <= money {
			do propose with: [message :: cfp, contents :: ['buy', price, money]];
		} else {
			do refuse with: [message :: cfp, contents :: ['', price, money]];
		}
		
	}
	
	aspect base
	{
		draw square(size) color: color;
	}
}


species SecurityGuard skills: [moving]
{
	float size <- 2.0;
	rgb color <- #purple;
	
	FestivalGuest targetAgent <- nil;
	
	reflex beIdle when: targetAgent = nil
	{
		do wander;
	}
	
	reflex targetAcquired when: targetAgent != nil and location distance_to(targetAgent) > 2
	{
		ask targetAgent {
			myself.targetAgent <- self;
		}
		do goto target: targetAgent;
	}
	
	reflex targetReached when: targetAgent != nil and location distance_to(targetAgent) <= 2
	{
		write "i'm sorry little one";
		ask targetAgent {
			do die;
		}
		targetAgent <- nil;
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
	
	FestivalGuest badAgent <- nil;
	
	reflex anyBadAgents
	{
		list<FestivalGuest> neighbors <- agents of_species FestivalGuest at_distance(5);
		if length(neighbors) > 0 
		{
			loop i from: 0 to: length(neighbors) - 1
			{
				FestivalGuest currentAgent <- neighbors at i;
				ask currentAgent {
					if self.isBad 
					{
						myself.badAgent <- self;
					}
				}
			}
		}
	}
	
	reflex notifyGuard when: badAgent != nil
	{
		SecurityGuard guard <- SecurityGuard closest_to(self);
		ask guard {
			if self.targetAgent = nil
			{
				self.targetAgent <- myself.badAgent;
				myself.badAgent <- nil;
			}
		}
	}
	
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

species Initiator skills: [fipa]
{
	int price <- 20000;
	int tmpPrice <- 20000;
	list<FestivalGuest> buyers <- [];
	list<FestivalGuest> allGuests <- agents of_species FestivalGuest at_distance(5000);
	
	bool sold <- false;
	bool started <- false;
	
	reflex notifyAuctionStart{
		write 'inform auction start';
		do start_conversation (to :: [allGuests], protocol :: 'fipa-request', performative :: 'informs', contents :: ['live auction']);
		
	}
	
	reflex collectParticipants when: (!empty(agrees))
	{
		loop a over: agrees 
		{
			add a.sender to: buyers;
		}
	}
	
	reflex start_auction when: !(empty(buyers)) and ((buyers where (each.location = auctionLocation)) contains_all (buyers)) and started = false
	{	
		tmpPrice <- price;
		started <- true;
		do start_conversation with: [ to :: list(buyers), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['price', tmpPrice] ];
	}
	
	reflex read_accepts when: !(empty(proposes)) {
		message auction <- first(proposes);
		sold <- true;
	}
	
	reflex lowerPrice when: sold = false and started = true 
	{
		tmpPrice <- tmpPrice - 1000;
		do start_conversation with: [ to :: list(buyers), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['price', tmpPrice] ];
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
			species SecurityGuard aspect: base;
		}
	}
}