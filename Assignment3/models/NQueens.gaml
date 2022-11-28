/**
* Name: NQueens
* Based on the internal empty template. 
* Author: perttuj & GGMorello
* Tags: 
*/

model NQueensTest

global {
	int numberOfQueens <- 12;
	int NboardDimensions <- 12;
	
	int index <- 0;
	
	bool debug <- false;

	// initially place all queens outside the board, and
	// insert them/generate positions one at a time
	point initialQueenPosition <- {-10, -10};

	string NO_POSITION_FOUND <- "no_position_found";
	string SET_POSITION <- "set_position";

	matrix<bool> occupationMatrix <- matrix_with ({NboardDimensions, NboardDimensions}, false);
	
	init {
		create Queen number: numberOfQueens;
		loop counter from: 1 to: numberOfQueens {
        	Queen queen <- Queen[counter - 1];
        	queen <- queen.setId(index);
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
	list<Queen> queens <- agents of_species Queen;
	
	init {
		location <- initialQueenPosition;
	}

	/** ACTIONS */
	action prettyPrintMatrix
	{
		write "Queen formation found:";
		loop row over: range(NboardDimensions - 1)
		{
			string s <- "";
			loop column over: range(NboardDimensions - 1)
			{
				bool cell <- getOccupationCell(row, column);
				if (cell = true) {
					s <- s + "1 ";
				} else {
					s <- s + "0 ";
				}
			}
			write s;
		}
	}
	
	bool getOccupationCell(int row, int col) {
		// the matrix uses the first index to specify columns,
		// and the second for rows - so we reverse the arguments
		// here so the prints we make of the matrix reflect
		// what the chessboard actually looks like in 2D
		return occupationMatrix[col, row];
	}
	
	action updateOccupationCell(int row, int col, bool val) {
		// see action above for details about why we reverse the col/row parameters here
		occupationMatrix[col, row] <- val;
		if debug = true {
			write self.name + ": occupation matrix updated, (" + row + "," + col + ") = " + val;	
			write occupationMatrix;
		}
	}
	
	action updateBoardCellOccupation(ChessBoard cell, bool val) {
		// see comments above why we reverse the y/x coordinates here
		do updateOccupationCell(cell.grid_y, cell.grid_x, val);
	}
	
	bool isRowSafe(int row) {
		// [0, numberOfQueens)
		loop currentCol over: range(NboardDimensions - 1) {
			if debug = true {
				write self.name + ": checking if row is safe: (" + row + "," + currentCol +")";
			}
			if (getOccupationCell(row, currentCol) = true) {
				if debug = true {
					write self.name + ": row is unsafe: (" + row + "," + currentCol + ")";	
				}
				return false;
			}
		}
		return true;
	}
	
	bool isDiagonalSafe(int cellRow, int cellColumn) {
		loop currentCol over: range(NboardDimensions - 1) {
			if currentCol != cellColumn {
				int diffX <- abs(cellColumn - currentCol);
				int row1 <- cellRow + diffX;
				int row2 <- cellRow - diffX;
				if (row1 < NboardDimensions) {
					if debug = true {
						write self.name + ": checking if diagonal is safe: (" + row1 + "," + currentCol + ")";
					}
					if (getOccupationCell(row1, currentCol) = true) {
						if debug = true {
							write self.name + ": diagonal is unsafe: (" + row1 + "," + currentCol + ")";
						}
						return false;
					}
				}
				if (0 <= row2 and row2 < NboardDimensions) {
					if debug = true {
						write self.name + ": checking if diagonal is safe: (" + row2 + "," + currentCol + ")";
					}
					if (getOccupationCell(row2, currentCol) = true) {
						if debug = true {
							write self.name + ": diagonal is unsafe: (" + row1 + "," + currentCol + ")";
						}
						return false;
					}
				}
			}
		}
		return true;
	}
	
	bool isColumnSafe(int col) {
		loop currentRow over: range(NboardDimensions - 1) {
			if debug = true {
				write self.name + ": checking if column is safe: (" + currentRow + "," + col + ")";
			}
			if (getOccupationCell(currentRow, col) = true) {
				if debug = true {
					write self.name + ": column is unsafe: (" + currentRow + "," + col + ")";
				}
				return false;
			}
		}
		return true;
	}
		
	action isCellSafe(int cellRow, int cellCol) {
		bool rowSafe <- isRowSafe(cellRow);
		bool diagonalSafe <- isDiagonalSafe(cellRow, cellCol);
		bool columnSafe <- isColumnSafe(cellCol);
		return rowSafe and diagonalSafe and columnSafe;
	}
	
	ChessBoard getBoardCell(int cellRow, int cellCol) {
		// Grid is composed of X and Y coordinates, so we reverse
		// the column/row properties here for clarity
		return ChessBoard[cellCol, cellRow];
	}

	action getNextPosition(int row, int col) {
		int nextRow <- row;
		int nextCol <- col + 1;
		if (nextCol >= NboardDimensions) {
			nextRow <- nextRow + 1;
			nextCol <- 0;
		}
		// if we've passed through all the rows, just return nil
		if (nextRow >= NboardDimensions) {
			if debug = true {
				write self.name + ": next pos for (" + row + "," + col + ") = [nil, nil]";
			}
			return [-1, -1];
		}
		if debug = true {
			write self.name + ": next pos for (" + row + "," + col + ") = (" + nextRow + "," + nextCol + ")";
		}
		return [nextRow, nextCol];
	}
	
	action askForNewPosition(int currRow, int currCol) {
		location <- initialQueenPosition;
		if debug = true {
			write self.name + ": asking for new position";	
		}
		myCell <- nil;
		if (pred = nil) {
			// if we're the first queen, generate a new position ourselves.
			// if we cannot find one, we've reached the end of the board and can exit
			list<int> nextPos <- getNextPosition(currRow, currCol);
			int nextRow <- nextPos[0];
			int nextCol <- nextPos[1];
			if nextRow = -1 or nextCol -1 {
				write self.name + ": cannot generated new position, end of board reached. ROW / COL / NboardDimensions: " + currRow + "/" + currCol + "/" + NboardDimensions; 
				int crash <- 100 / 0;
			}
			ChessBoard newCell <- getBoardCell(nextRow, nextCol);
			// since we're the first queen, we can always set the occupation
			// matrix value to true here - since no other queens should be on the board
			// at this point
			do updateOccupationCell(nextRow, nextCol, true);
			myCell <- newCell;
			location <- newCell.location;
			list<int> succPos <- getNextPosition(nextRow, nextCol);
			int succRow <- succPos[0];
			int succCol <- succPos[1];
			if debug = true {
				write self.name + ": generated new pos, assigning new pos to successor: " + nextPos + ";" + succPos;
			}
			do informOfNewPosition(succRow, succCol);
		} else {
			do start_conversation (to :: list(pred), protocol :: 'fipa-request', performative :: 'inform', contents :: [NO_POSITION_FOUND, currRow, currCol]);
		}
	}
	
	action informOfNewPosition(int row, int col) {
		do start_conversation (to :: list(succ), protocol :: 'fipa-request', performative :: 'inform', contents :: [SET_POSITION, row, col]);
	}

	action handleSetPosition(list<string> content) {
		int cellRow <- content[1] as int;
		int cellColumn <- content[2] as int;
		
		ChessBoard newCell <- getBoardCell(cellRow, cellColumn);
		
		if (myCell != nil) {
			do updateBoardCellOccupation(myCell, false);
			myCell <- nil;
		}
		
		bool isNewCellTaken <- getOccupationCell(cellRow, cellColumn) = true;
		
		if (isNewCellTaken or !isCellSafe(cellRow, cellColumn)) {
			if debug = true {
				write self.name + ": new cell is taken or unsafe (" + cellRow + "," + cellColumn + "), asking predecessor for new location";
			}
			do askForNewPosition(cellRow, cellColumn);
		} else {
			list<int> pos <- getNextPosition(cellRow, cellColumn);
			int successorRow <- pos[0];
			int successorCol <- pos[1];
			if (succ != nil) {
				if debug = true {
					write self.name + ": assigning position for next queen: " + succ.name + ", pos: (" + successorRow + "," + successorCol + ")";
				}
				if (successorRow = -1 or successorCol = -1) {
					write self.name + ": couldn't generate new position for successor (current pos: (" + cellRow + "," + cellColumn + "). Asking predecessor for repositioning";
					do askForNewPosition(cellRow, cellColumn);
					return;
				}
			}
			myCell <- newCell;
			location <- newCell.location;
			do updateBoardCellOccupation(newCell, true);
			if (succ != nil) {
				do informOfNewPosition(successorRow, successorCol);
			} else {
				do prettyPrintMatrix;
				// keep looking for new formations
				do askForNewPosition(cellRow, cellColumn);
			}
		}
	}
	
	reflex initializeFirstQueen when: id != nil and id = 0 and myCell = nil and succ != nil {
		if debug = true
		{
			write self.name + ": Initializing first queen";
		}
		myCell <- getBoardCell(0, 0);
		location <- myCell.location;
		do updateBoardCellOccupation(myCell, true);
		do informOfNewPosition(1, 2);
	}
	
	action handleAssignNewPosition(list<string> content) {
		int prevCellRow <- content[1] as int;
		int prevCellCol <- content[2] as int;
		
		list<int> nextPos <- getNextPosition(prevCellRow, prevCellCol);
		int nextCellRow <- nextPos[0];
		int nextCellCol <- nextPos[1];
		
		if debug = true {
			write self.name + ": assigning new position, prev: (" + prevCellRow + "," + prevCellCol + "), next: (" + nextCellRow + "," + nextCellCol + ")";
		}
		
		int remainingQueens <- numberOfQueens - id;
		// since we're placing queens on the next row each time, we can avoid a lot of
		// repetitive checks if we just stop attempting to place queens when we're running
		// out of space. For example, on a 4x4 board, if we're on row 3/4 and have 3 queens
		// left to place, there is no point in even trying - there are too few rows left,
		// so we should just ask our predecessor for a new position
		bool runningOutOfSpace <- NboardDimensions - nextCellRow < remainingQueens - 1;
		if (nextCellRow = -1 or nextCellCol = -1 or runningOutOfSpace) { // 
			do updateBoardCellOccupation(myCell, false);
			int currRow <- myCell.grid_y as int;
			int currCol <- myCell.grid_x as int;
			myCell <- nil;
			do askForNewPosition(currRow, currCol);
		} else {
			do informOfNewPosition(nextCellRow, nextCellCol);
		}
	}
	
	reflex receiveInform when: !empty(informs) {
		list<string> content <- informs[0].contents;
		// informType = either "set_position" (from pred) or no_position_found (from succ)
		string informType <- content[0];
		if debug = true {
			write self.name + ": received inform of type: " + informType + " content: " + content[1] + " " + content[2];
		}
		if (informType = SET_POSITION) {
			do handleSetPosition(content);
		} else if (informType = NO_POSITION_FOUND) {
			do handleAssignNewPosition(content);
		} else {
			// TODO throw an actual exception?
			int crash <- 100 / 0;
		}
	}
	
    reflex updateCell {
    	if id > 0 and pred = nil {
    		Queen predq <- queens[id - 1];
    		pred <- predq;
    	}
    	if id + 1 < numberOfQueens and succ = nil {
    		Queen succq <- queens[id + 1];
    		succ <- succq;
    	}
    }

	action setId(int newId) {
		id <- newId;
	}
	
	float size <- 30 / NboardDimensions;
	
	aspect base {
        draw circle(size) color: #blue;
    }
}

grid ChessBoard skills: [fipa] width: NboardDimensions height: NboardDimensions {
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