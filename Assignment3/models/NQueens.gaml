/**
* Name: NQueens
* Based on the internal empty template. 
* Author: perttuj & GGmorello
* Tags: 
*/

model NQueens


global {
	
	int numberOfQueens <- 12;

	init {
		int index <- 0;
		create Queen number: numberOfQueens;
		
		loop counter from: 1 to: numberOfQueens {
        	Queen queen <- Queen[counter - 1];
        	if counter > 1 {
        		Queen predq <- Queen[counter - 2];
        		write "predq: " + counter + " - " + predq.id;
        		queen <- queen.setPred(predq);
        	}
        	if counter < numberOfQueens {
        		Queen succq <- Queen[counter];
        		write "succq" + counter + " - " + succq.id;
        		queen <- queen.setSucc(succq);
        	}
        	queen <- queen.setId(index);
        	queen <- queen.initializeCell();
        	index <- index + 1;
        }
	}
}


species Queen skills: [fipa] {
    
	ChessBoard myCell; 
	int id; 
	int index <- 0;
	Queen pred <- nil;
	Queen succ <- nil;
       
    reflex updateCell {
    	myCell <- ChessBoard[myCell.grid_x,  mod(index, numberOfQueens)];
    	location <- myCell.location;
    	index <- index + 1;
 
 		if pred != nil {
 			write "" + id + ": pred: " + pred.id;
 		} else {
 			write "" + id + ": pred: nil";
 		}
 		
 		if succ != nil {
 			write "" + id + ": succ: " + succ.id;
 		} else {
 			write "" + id + ": succ: nil";
 		}
    }

	action setId(int input) {
		id <- input;
	}
	
	action initializeCell {
		myCell <- ChessBoard[id, id];
	}
	
	action setPred(Queen p) {
		pred <- p;
	}
	
	action setSucc(Queen s) {
		succ <- s;
	}
	
	float size <- 30/numberOfQueens;
	
	aspect base {
        draw circle(size) color: #blue ;
       	location <- myCell.location ;
    }

}
    
    
grid ChessBoard width: numberOfQueens height: numberOfQueens { 
	init{
		if(even(grid_x) and even(grid_y)){
			color <- #black;
		}
		else if (!even(grid_x) and !even(grid_y)){
			color <- #black;
		}
		else {
			color <- #white;
		}
	}		

}

experiment NQueens type: gui{
	output{
		display ChessBoard{
			grid ChessBoard border: #black ;
			species Queen aspect: base;
		}
	}
}