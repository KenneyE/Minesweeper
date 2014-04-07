require 'debugger'


class MineSweeper

  REVEAL = "r"
  FLAG = "f"

  def prompt(s)
    puts(s)
    return gets.chomp.strip.downcase
  end

  def parse(s)
    arr = s.split(",").map{|el| el.to_i - 1}
  end

  def valid_pos(p)
    p.length == 2 && p[0].between?(0, @board.width - 1) && p[1].between?(0, @board.height - 1)
  end


  attr_accessor :board

  def play

    @board = Board.new(prompt("Enter the board size: "))

    until won? || lost?

      system("clear")
      @board.display

      begin
        pos = parse(prompt("Enter a position: "))
      end until valid_pos(pos)


      begin
        action = prompt("Enter an action (F = flag, R = reveal): ")
      end until action == FLAG || action == REVEAL

      @board[pos].reveal if action == REVEAL
      @board[pos].flag if action == FLAG
    end
  end

  def won?

    no_unexplored = true

    @board.tiles.each do |row|
      row.each do |col|
        no_unexplored = false if col.piece == Tile::UNEXPLORED
      end
    end

    no_unexplored

  end


  def lost?

    bombed = false

    @board.tiles.each do |row|
      row.each do |col|
        bombed = true if col.piece == Tile::BOMBED
      end
    end
    bombed
  end

end

class Tile

  UNEXPLORED = "*"
  INTERIOR = "_"
  FLAGGED = "F"
  BOMBED = "B"

  attr_accessor :piece, :bomb, :pos
  attr_reader :board

  def initialize(pos = [], board)
    @piece = UNEXPLORED
    @pos = pos
    @board = board
    @bomb = false
  end

  def is_bomb?
    bomb
  end

  def flagged?
    self.piece == FLAGGED
  end

  def bombed?
    self.piece == BOMBED
  end

  def revealed?
    self.piece == INTERIOR || self.piece.between?('1', '8')
  end

  def flag
    self.piece = FLAGGED
  end

  def reveal
    if self.is_bomb?
      piece = BOMBED
    else

      n = neighbor_bomb_count

      if n > 0
        piece = n.to_s
      else
        neighbors.each do |neighbor|
          neighbor.reveal
        end

      end

    end
  end


  def neighbors
    arr = []
    relative_pos = [[0,1], [0,-1],[1,1], [1,0], [1,-1], [-1,0], [-1,-1], [-1, 1]]
    relative_pos.each do |rpos|
      x = self.pos[0] + rpos[0]
      y = self.pos[1] + rpos[1]

      arr << self.board[[x,y]] if x.between?(0,self.board.width - 1) && y.between?(0,self.board.height - 1)
    end

    arr
  end

  def neighbor_bomb_count
    bomb_count = 0
    neighbors.each do |neighbor|
      bomb_count += 1 if neighbor.is_bomb?
    end
    bomb_count
  end
end

class Board
  attr_accessor :tiles, :width, :height
  def initialize(board_size = "small")
    @width, @height = 8 , 8 if board_size.downcase == "small"
    @tiles = Array.new(@height) { Array.new(@width) {Tile.new([], self)} }
    #debugger
    initialize_tiles
  end

  def initialize_tiles
    self.tiles.each_with_index do |row, i|
      row.each_with_index do |col, j|
        self.tiles[i][j].pos = [i, j]
      end
    end

    num_bombs = 0
    until num_bombs == 10
      tile = self.tiles.sample.sample
      unless tile.is_bomb
        tile.is_bomb = true
        num_bombs += 1
      end
    end
  end

  def to_s
    s = ""
    self.tiles.each_with_index do |row, i|
      row.each_with_index do |col, j|
        s += self.tiles[i][j].piece + " "
      end
      s += "\n"
    end
    s
  end

  def [](pos)
    self.tiles[pos[0]][[pos[1]]
  end

  def display
    puts self.to_s
  end


end