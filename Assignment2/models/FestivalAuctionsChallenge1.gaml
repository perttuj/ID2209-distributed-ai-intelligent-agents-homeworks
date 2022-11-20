/**
* Name: FestivalAuctionsChallenge1
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model FestivalAuctionsChallenge1

global {
	int numberOfPeople <- 21;
	
	int numberOfFoodStores <- 2;
	int numberOfDrinkStores <- 2;
	int numberOfDrinkFoodStores <- 2;
	
	int numberOfInfoCenter <- 1;
	
	int distanceThreshold <- 10;
	
	int numberOfSecurity <- 1;
	
	int initialGuestMoneyMaxRange <- 10000;
	int initialAuctionPrice <- 20000;
	int minimumAuctionPrice <- 5000;
	int auctionDistanceThreshold <- 10;
	
	string CD_ITEM_TYPE <- "CD_ITEM_TYPE";
	rgb CD_ITEM_COLOR <- #teal;
	
	string CLOTHING_ITEM_TYPE <- "CLOTHING_ITEM_TYPE";
	rgb CLOTHING_ITEM_COLOR <- #orange;

	string VIP_TICKET_ITEM_TYPE <- "VIP_TICKET_ITEM_TYPE";
	rgb VIP_ITEM_COLOR <- #purple;
	
	point informationCenterLocation <- {50,75};
	point auctionLocation <- {50, 50};
	
	init {
		create FestivalGuest number: numberOfPeople / 3
		{
			interestedInItemType <- CD_ITEM_TYPE;
			color <- CD_ITEM_COLOR;
		}
		create FestivalGuest number: numberOfPeople / 3
		{
			interestedInItemType <- CLOTHING_ITEM_TYPE;
			color <- CLOTHING_ITEM_COLOR;
		}
		create FestivalGuest number: numberOfPeople / 3
		{
			interestedInItemType <- VIP_TICKET_ITEM_TYPE;
			color <- VIP_ITEM_COLOR;
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
		// create SecurityGuard number: numberOfSecurity;
		
		create DutchAuctioneer
		{
			location <- {25, 50};
			itemType <- CD_ITEM_TYPE;
			color <- CD_ITEM_COLOR;
		}
		create DutchAuctioneer
		{
			location <- {50, 50};
			itemType <- VIP_TICKET_ITEM_TYPE;
			color <- VIP_ITEM_COLOR;
		}
		create DutchAuctioneer
		{
			location <- {75, 50};
			itemType <- CLOTHING_ITEM_TYPE;
			color <- CLOTHING_ITEM_COLOR;
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
	
	Auctioneer joinedAuction <- nil;
	
	int money <- 0;
	string interestedInItemType;
	
	init {
		money <- rnd(0, initialGuestMoneyMaxRange);
	}
	
	reflex beIdle when: targetPoint = nil
	{
		do wander;
		
		if (flip(0.01)) {
			money <- money + rnd(1);	
		}
		
		/*if (flip(0.001)) {
			isBad <- true;
			color <- #black;
		}*/
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
		/* if self.isBad 
		{
			color <- #black;
		} 
		else {
			color <- #blue;
		} */
		if self.interestedInItemType = CD_ITEM_TYPE {
			color <- CD_ITEM_COLOR;
		} else if self.interestedInItemType = CLOTHING_ITEM_TYPE {
			color <- CLOTHING_ITEM_COLOR;
		} else if self.interestedInItemType = VIP_TICKET_ITEM_TYPE {
			color <- VIP_ITEM_COLOR;
		} else {
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
		message requestFromAuctioneer <- informs[0];
		string informType <- requestFromAuctioneer.contents[0];
		if (informType = "start_auction") {
			// write self.name + ": auction started";
			string auctionType <- requestFromAuctioneer.contents[1];
			string auctionItemType <- requestFromAuctioneer.contents[2];
			Auctioneer auctioneer <- requestFromAuctioneer.contents[3] as Auctioneer;
			if auctionItemType = interestedInItemType and joinedAuction = nil and THIRST > 10000 and HUNGER > 10000 and money > 0 {
				// write self.name + ": accepting invitation, item type: " + auctionItemType + ", interest: " + interestedInItemType;
				do agree with: (message: requestFromAuctioneer, contents: [self.name + ': I will']);
				joinedAuction <- auctioneer;
			} else {
				// write self.name + ": refusing invitation for item type: " + auctionItemType + ", money: " + money + ", interest: " + interestedInItemType;
				do refuse with: (message: requestFromAuctioneer, contents: [self.name + ': I won\'t']);
			}
		} else if (informType = "end_auction") {
			// write self.name + ": auction ended"; 
			Auctioneer auctioneer <- requestFromAuctioneer.contents[1] as Auctioneer;
			if (joinedAuction != nil and joinedAuction.name = auctioneer.name) {
				joinedAuction <- nil;
			}
		}
	}
	
	reflex gotoAuction when: joinedAuction != nil and location distance_to joinedAuction > auctionDistanceThreshold - 5
	{
		do goto target: joinedAuction;
	}
	
	reflex respondToCfp when: (!empty(cfps)) {
		message cfp <- cfps at 0;
		list<string> content <- cfp.contents as list<string>;
		int price <- content at 1 as int;
		if price <= money {
			// write self.name + ": propsing purchase"; 
			do propose message: cfp contents: ['buy', price, money];
		} else {
			// write self.name + ": refusing proposal"; 
			do refuse message: cfp contents: ['im poor', price, money];
		}	
	}
	
	reflex receiveAcceptProposals when: !empty(accept_proposals) {
		// write(self.name + ': proposal accepted');		
		loop acceptMsg over: accept_proposals {
			do inform message: acceptMsg contents:["Inform from " + name];
			list<string> content <- acceptMsg.contents[0] as list<string>;
			int price <- content at 1 as int;
			money <- money - price;
		}
		joinedAuction <- nil;
	}

	reflex recieveRejectProposals when: !empty(reject_proposals) {
		// write(self.name + ': proposal rejected');		
		loop rejectMsg over: reject_proposals {
			// Read content to remove the message from reject_proposals variable.
			string dummy <- rejectMsg.contents[0];
		}
		joinedAuction <- nil;
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

species Auctioneer skills: [fipa]
{
	int price <- initialAuctionPrice;
	int tmpPrice <- initialAuctionPrice;

	list<FestivalGuest> buyers <- [];
	list<FestivalGuest> allGuests <- agents of_species FestivalGuest;
	
	string auctionType; // should be set in sub-species
	string itemType; // should be set in sub-species
	bool sold <- false;
	bool started <- false;
	bool initiated <- false;

	float size <- 2.0;
	rgb color <- #red;
	
	action proposePrice
	{
		do start_conversation (to :: buyers, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['price', tmpPrice]);
	}
	
	action announceAuction
	{		
		do start_conversation (to :: allGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: ['start_auction', auctionType, itemType, self]);
	}
	
	action cancelAuction
	{
		initiated <- false;
		started <- false;
		sold <- true;
		do endAuction;
	}
	
	action endAuction 
	{
		do start_conversation (to :: buyers, protocol :: 'fipa-request', performative :: 'inform', contents :: ['end_auction', self]);
		buyers <- [];
	}
	
	reflex startNewAuction when: started = false and sold = true {
		// occasionally start a new auction
		if (flip(0.001)) {
			// setting sold to false will trigger our other reflex below,
			// which sends an inform to all agents
			tmpPrice <- initialAuctionPrice;
			initiated <- false;
			sold <- false;
		}
	}

	reflex notifyAuctionStart when: initiated = false and sold = false {
		write self.name + ': informing guests of new auction, item type: ' + itemType;
		initiated <- true;
		do announceAuction;
	}

	reflex collectParticipants when: initiated = true and started = false and (!(empty(agrees)) or !(empty(refuses)))
	{
		int sizeOfAgrees <- 0;
		int sizeOfRefuses <- 0;
		loop a over: agrees 
		{
			sizeOfAgrees <- sizeOfAgrees + 1;
			add a.sender to: buyers;
			string dummy <- a.contents;
		}
		loop r over: refuses
		{
			sizeOfRefuses <- sizeOfRefuses + 1;
			string dummy <- r.contents;
		}
		write self.name + ": size of agrees = " + sizeOfAgrees + "; size of refuses: " + sizeOfRefuses;
		if (sizeOfAgrees = 0) {
			// wait until later to start another auction if nobody is interested at this time
			write self.name + ": cancelling auction, no participants interested";
			write "";
			initiated <- false;
			sold <- true;
		}
	}

	reflex startAuction when: initiated = true and started = false and !(empty(buyers))
		and ((buyers where (each.location distance_to self.location < auctionDistanceThreshold)) contains_all (buyers))
	{	
		write self.name + ": all guests arrived - starting new auction";
		tmpPrice <- price;
		started <- true;
		do proposePrice;
	}
	
	reflex readProposals when: started = true and !(empty(proposes)) {
		int proposalsSize <- length(proposes);
		bool accepted <- false;
		loop proposeMsg over: proposes {
			if (accepted = false) {
				accepted <- true;
				write self.name + ": accepting proposal from " + proposeMsg.sender + ", price: " + tmpPrice;
				do accept_proposal message: proposeMsg contents: ["Congratulations!"];
			} else {
				do reject_proposal message: proposeMsg contents: ["Too slow"];
			}
			
			// we need to do this so that the proposes aren't repeatedly looped through
			string dummy <- proposeMsg.contents;
		}
		write "";
		sold <- true;
		started <- false;
		do endAuction;
	}

	aspect base
	{
		draw circle(size) color: color;
	}
}

species DutchAuctioneer parent: Auctioneer
{
	init {
		auctionType <- "dutch";
	}
	
	reflex receiveRefuseMessages when: started = true and !(empty(refuses)) {
		int lengthOfRefuses <- 0;
		loop refuseMsg over: refuses {
			lengthOfRefuses <- lengthOfRefuses + 1;
			// Read content to remove the message from refuses variable.
			string dummy <- refuseMsg.contents[0];
		}
		
		// if all buyers refused the price, start another round of negotiations
		if (lengthOfRefuses = length(buyers)) {
			tmpPrice <- tmpPrice - rnd(100);
			// write self.name + ": lowering price to: " + tmpPrice;
			if (tmpPrice >= minimumAuctionPrice) {
				do proposePrice;
			} else {
				write self.name + ": new price (" + tmpPrice + ") is below the minimum (" + minimumAuctionPrice + ") - cancelling auction";
				write "";
				do cancelAuction;
			}
		}
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
			species DutchAuctioneer aspect: base;
		}
	}
}