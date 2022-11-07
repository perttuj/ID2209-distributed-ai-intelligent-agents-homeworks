/**
* Name: NewModel
* Based on the internal empty template. 
* Author: perttuj
* Tags: 
*/


model Festival

global {
	int numberOfPeople <- 10;
	int numberOfStores <- 3;
	
	init {
		create Person number:numberOfPeople;
		create Store number:numberOfStores;
	}
}

species Person {
	bool isHungry <- false;
	bool isThirsty <- false;
	
	aspect base {
		rgb agentColor <- rgb("green");
		
		if (isHungry and isThirsty) {
			agentColor <- rgb("red");
		} else if (isThirsty) {
			agentColor <- rgb("darkorange");
		} else if (isHungry) {
			agentColor <- rgb("purple");
		}
		
		draw circle(1) color: agentColor;
	}
}


species Store {
	// It doesn't make sense to have a store without any food and drink. It is just for demo!
	bool hasFood <- flip(0.5);
	bool hasDrink <- flip(0.5);	
	
	aspect base {
		rgb storeColor <- rgb("lightgray");
		
		draw square(2) color: storeColor;
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			species Person aspect:base;
			species Store aspect:base;
		}
	}
}