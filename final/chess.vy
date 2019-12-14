# PIECES:
# 0   none
# 1   pawn (white)
# -2  bishop (black)
# 3   knight (white)
# -4  rook (black)
# 5   queen (white)
# -6  king (black)

# Define structs
struct coord:
    col: uint256
    row: uint256
 
#struct tile:
    #loc: coord
    #p: int128
    
#struct column:
    #t: tile[8]
    #t: map(uint256,tile)

# For now, assume 8x8 board
struct board:
    #rows: uint256
    #cols: uint256
    
    #none of these definitions for tiles will compile
    #tiles: tile[8][8]
    #tiles: column[8]
    #tiles: map(uint256,column)
    #tiles: map(uint256,map(uint256,uint256))
    
    tiles: int128[8][8]
    
    white: bool # white to move
    enP: coord # latest en passant move
    lastmove: uint256 # latest move time
    moves: uint256 # how many total moves


# public variables
house: public(address)
player1: public(address)
player2: public(address)
moveTime: public(uint256)
bet: public(uint256)
brd: public(board)
wPaid: public(bool)
bPaid: public(bool)


# functions




# initialize board; for now, assume standard chess board
@private
def populateBoard(b: board):
    p: int128 = 0
    n: int128[8] = [4,3,2,5,6,2,3,4] #R,N,B,Q,K,B,N,R
    
    # initialize empty board
    for i in range(8):
        for j in range(8):
            b.tiles[i][j] = p
        
    # Add pieces (assume standard start)
    for i in range(8):
        # black pawns
        p = -1
        b.tiles[i][6] = p
        # white pawns
        p = 1 # white pawn
        b.tiles[i][1] = p
        # other pieces
        p = n[i] # white pieces
        b.tiles[i][0] = p
        p = p * -1 # black pieces
        b.tiles[i][7] = p
        
    # set moves to 0, enP to 0,0
    b.white = True
    b.enP = coord({row: 0,col: 0})
    

# internal functions

# get player whose turn it is; player1 = 1 = white, black = -1
@private
@constant
def getPlayer() -> int128:
    if self.brd.white:
        return 1
    return -1


# check if a player has timed out
@private
def timeout(player: int128) -> bool:
    if block.timestamp > self.brd.lastmove + self.moveTime \
            and self.brd.moves > 0 \
            and (self.brd.white==(player==1)):
        return True
    return False

# check if a player has lost their king
@private
def noKing(player: int128) -> bool:
    for i in range(8):
        for j in range(8):
            if self.brd.tiles[i][j] == player*6: # white/black king
                return False
    return True

# update board with valid move
@private
def enactMove(here: coord, there: coord, promotion: uint256, ep: bool):
    player: int128 = self.getPlayer()
    
    # change target to current piece
    temp: int128 = self.brd.tiles[here.col][here.row]
    self.brd.tiles[there.col][there.row] = temp 
    
    # remove piece from current tile
    self.brd.tiles[here.col][here.row] = 0
    
    # reset en passant tracker
    self.brd.enP.col = 0 # this is a safe "null" value because en passant on this
    self.brd.enP.row = 0 # will move attacker off the board, already checked for
    
    # if en passant, update tracker and remove piece
    if ep:
        self.brd.enP.col = there.col
        self.brd.enP.row = there.row + convert(player * -1,uint256)
        self.brd.tiles[there.col][there.row + convert(player * -1,uint256)] = 0
    
    # if promotion, promote
    if (there.row == 7 or there.row == 0) \
            and (self.brd.tiles[here.col][here.row] == 1 or \
            self.brd.tiles[here.col][here.row] == -1):
        self.brd.tiles[there.col][there.row] = convert(promotion,int128) * player
    
    # update move timer
    self.brd.lastmove = as_unitless_number(block.timestamp)



    
    
# Functions for checking if a move is valid:


# check the coords exist and are not equal
@private
def onBoard(here: coord, there: coord) -> bool:
    return here.col < 8 and here.row < 8 and there.col < 8 and there.row < 8 and here != there

# confirm the correct player owns what's "here"
@private
def occupies(here: coord) -> bool:
    turn: int128 = self.getPlayer() # white 1 black -1
    occ: int128 = self.brd.tiles[here.col][here.row] # white +, black -, no piece 0

    # check if signs match    
    if turn * occ > 0:
        return True
    return False

# check the target coord does not contain friendly piece
@private
def notOccupied(there: coord) -> bool:
    player: int128 = getPlayer()
    # if piece matches player (+ or -)
    if self.brd.tiles[there.col][there.row] * player > 0:
        return False
    return True
    
# check for rook's movement
@private
def validRook(here: coord, there: coord) -> bool:
    # must be either valid x or y movement
    # check tiles for interfering row movement
    validX: bool = here.col == there.col
    if validX:
        high: uint256 = max(here.row, there.row)
        low: uint256 = min(here.row, there.row)
        for i in range(low+1,high):
            if self.brd.tiles[here.col][i] != 0:
                return False
        return True
    
    # check tiles for interfering column movement
    validY: bool = here.row == there.row
    if validY:
        high: uint256 = max(here.col, there.col)
        low: uint256 = min(here.col, there.col)
        for i in range(low+1,high):
            if self.brd.tiles[i][here.row] != 0:
                return False
        return True
    
    # if neither valid x nor y, return false
    return False
    
# check for bishop's movement
@private
def validBish(here: coord, there: coord) -> bool:
    # left to right, bottom to top: determine direction of travel
    L2R: bool = here.col < there.col
    B2T: bool = here.row < there.row
    
    # assert equal change in rows and cols
    deltaX: uint256
    if LTR:
        deltaX = there.col - here.col
    else:
        deltaX = here.col - there.col
        
    deltaY: uint256
    if B2T:
        deltaY = there.row - here.row 
    else:
        deltaY = here.row - there.row
    if deltaX != deltaY:
        return False
    
    # tile checker will check left to right
    left: uint256
    if L2R:
        left = here.col
    else:
        left = there.col
    right: uint256
    if L2R:
        right = there.col
    else:
        right = here.col

    # tile checker will start at leftmost x AND y coord
    first: uint256 
    if L2R:
        first = here.row
    else:
        first =  there.row
    # If moving up, count up, else count down
    step: int128 
    if B2T:
        step = 1
    else:
        step = -1
        
    
    # check tiles for interfering pieces
    # deltaX = deltaY = # of diagonal squares
    for i in range(1,deltaX):
        if self.brd.tiles[low + i][first + (i * step)] != 0:
            return False
        
    # if no collisions,
    return True

# check for knight's movement
@private
def validKnight(here: coord, there: coord) -> bool:
    # left to right, bottom to top: determine direction of travel
    L2R: bool = here.col < there.col
    B2T: bool = here.row < there.row
    
    # assert L shape movement
    deltaX: uint256 
    if L2R:
        deltaX = there.col - here.col
    else:
        deltaX = here.col - there.col

    deltaY: uint256 
    if B2T:
        deltaY = there.row - here.row
    else:
        deltaY = here.row - there.row

    return deltaX>0 and deltaY>0 and deltaX + deltaY == 3
    
# check for king's movement
@private
def validKing(here: coord, there: coord) -> bool:
    # left to right, bottom to top: determine direction of travel
    L2R: bool = here.col < there.col
    B2T: bool = here.row < there.row
    
    # assert max delta 1 each direction
    deltaX: uint256 
    if L2R:
        deltaX = there.col - here.col
    else:
        deltaX = here.col - there.col

    deltaY: uint256 
    if B2T:
        deltaY = there.row - here.row
    else:
        deltaY = here.row - there.row
    
    return deltaX < 2 and deltaY < 2
    
# check for pawn's movement (multiple cases)
@private
def validPawn(here: coord, there: coord, promotion: uint256, ep: bool) -> bool:
    # left to right, bottom to top: determine direction of travel
    L2R: bool = here.col < there.col
    B2T: bool = here.row < there.row
    
    # define movement
    deltaX: uint256 
    if L2R:
        deltaX = there.col - here.col
    else:
        deltaX = here.col - there.col

    deltaY: uint256 
    if B2T:
        deltaY = there.row - here.row
    else:
        deltaY = here.row - there.row
    
    # white (player1) = 1, black = -1
    player: int128 = self.getPlayer()

    # case: move one forward
    if deltaY == 1 and deltaX == 0 and (B2T == (player == 1)):
        # can never take a piece; reject if occupied
        if self.brd.tiles[there.col][there.row] != 0:
            return False
        # check if promotion    
        if there.row == 7 or there.row == 0:
            # check promotion is correct color and piece
            if not (promotion in range(2,6)): #[2,3,4,5], B,N,R,Q
                return False
        return True
    
    # case: move two forward
    if deltaY == 2 and deltaX == 0 and (B2T == (player == 1)):
        # the following is sufficient to see if two squares is allowed;
        # two squares the other way is off the board, checked separately
        if not (here.row == 1 or here.row == 6):
            return False
        # this movement cannot take pieces
        for i in [1,2]:
            # if either tile is occupied, reject
            if self.brd.tiles[here.col][here.row + i*player] != 0:
                return False
        return True
        
    # case: take diagonally forward
    if deltaY == 1 and deltaX == 1 and (B2T == (player == 1)):
        # check if diagonal piece is opponent's (and NOT en passant)
        if self.brd.tiles[there.col][there.row] * player < 0 \
                and not ep:
            return True
        # check if en passant is allowed
        if self.brd.tiles[there.col][there.row + -1*player] * player < 0 \
                and self.brd.enP.col == there.col \
                and self.brd.enP.row == there.row + -1*player \
                and ep:
            return True
        # if neither capture is possible
        return False
    # if no cases apply
    return False

# check if valid queen (just rook and bishop)
@private
def validQueen(here: coord, there:coord) -> bool:
    return validRook(here, there) or validBish(here, there)
    
    
# check if move is valid (everything)
@private
def validMove(here: coord, there: coord, promotion: uint256, ep: bool) -> bool:
    # If one of the coordinates is not on the board, or they're the same, return false
    if not self.onBoard(here,there):
        return False
    # If there is no friendly piece "here", return false
    if not self.occupies(here):
        return False
    # If you are trying to capture your own piece, return false
    if not self.notOccupied(there):
        return False
    
    # check validity by piece type
    moving: int128 = self.brd.tiles[here.col][here.row]
    player: int128 = getPlayer()
    abs: int128 = moving * player # normalize >0
    
    if abs == 1:
        return validPawn(here,there,promotion,ep)
    if abs == 2:
        return validBish(here,there)
    if abs == 3:
        return validKnight(here,there)
    if abs == 4:
        return validRook(here,there)
    if abs == 5:
        return validQueen(here,there)
    if abs == 6:
        return validKing(here,there)
    
    assert 1 == 0
    
    return False
    


    





@public
@payable
def __init__(_owner: address, _timer: uint256, _bet: uint256, p1: address, p2: address):
    self.moveTime = _timer
    self.bet = _bet
    self.wPaid = False
    self.bPaid = False
    self.house = _owner
    self.player1 = p1
    self.player2 = p2

    #self.populateBoard(self.brd)
    

# callable functions

# join
@public
@payable
def join():
    #assert(as_unitless_number(msg.value) >= self.bet)
    assert(msg.value >= self.bet)
    if msg.sender == self.player1:
        self.wPaid = True
    elif msg.sender == self.player2:
        self.bPaid = True
        
    self.populateBoard(self.brd)


# owner claims victory after 100 moves, or long timeout (10 * timeout)
@public
def houseVic():
    assert(msg.sender == self.house)
    if not (self.brd.moves > 100 or \
            block.timestamp > self.brd.lastmove + self.moveTime * 10):
        assert(1 == 0)
    
    selfdestruct(self.house)
    

# play your move
@public
def move(fromCol: uint256, fromRow: uint256, toCol: uint256, toRow: uint256, promotion: uint256=5, ep: bool = False):
    # make sure right person is calling function
    if self.brd.white:
        assert(msg.sender == self.player1)
    else:
        assert(msg.sender == self.player2)
        
    # assert game has started
    assert(self.wPaid and self.bPaid)
    
    #create coords
    here: coord = coord({col: fromCol, row: fromRow})
    there: coord = coord({col: toCol, row: toRow})
    
    # validate move
    assert(validMove(here,there,promotion,ep))
    
    # enact move
    enactMove(here,there,promotion,ep)
    
# claim victory
@public
def claimVic():
    player: int128
    # assert a player is claiming
    if msg.sender == player1:
        player = 1
    elif msg.sender == player2:
        player = -1
    else:
        assert(1 == 0)
    
    # check if any victory conditions are met
    if not (timeout(player*-1) or noKing(player*-1)):
        assert(1 == 0)
        
    # pay out to winner
    selfdestruct(msg.sender)
