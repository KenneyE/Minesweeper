require 'debugger'
require 'yaml'

# encoding: utf-8

class MineSweeper

  REVEAL = "r"
  FLAG = "f"
  attr_accessor :board, :quit

  def initialize
    @quit = false
    @board = nil
  end

  def play(filename = "")
    self.board = define_board(filename)
    quit = false

    until won? || lost? || quit
      system("clear")
      self.board.display
      #debugger
      move = get_move

      if self.quit
        save_file
        break
      end
    end

    self.board.cheat
    puts "CONGRATS!!!!!" if won?
    puts "You lost..." if lost?

  end

  private

    def get_move
      k = get_key
      case k
      when 'a'
        move_cursor(k)
      when 's'
        move_cursor(k)
      when 'd'
        move_cursor(k)
      when 'w'
        move_cursor(k)
      when 'q'
        self.quit = true
      when 'r'
        self.board[get_cursor].reveal
      when 'f'
        self.board[get_cursor].flag
      end
    end

    def define_board(filename)
      unless filename.empty?
        self.board = YAML::load_file(ARGV.shift)
      else
        size       = prompt("Enter the board size (Enter none for small): ")
        size       = "small" if size.empty?
        self.board     = Board.new(size)
      end
    end

    def save_file
      y = self.board.to_yaml
      filename = prompt("Enter the filename to save game: ")
      File.open(filename, "w") {|f| f.print(y)} unless filename.empty?
    end

    def won?
      self.board.tiles.each do |row|
        row.each {|col| return false if col.piece == Tile::UNEXPLORED}
      end
      true
    end

    def lost?
      self.board.tiles.each do |row|
        row.each { |col| return true if col.piece == Tile::BOMBED }
      end
      false
    end

    def prompt(s)
      puts(s)
      return gets.chomp.strip.downcase
    end

    def parse(s)
      arr = s.split(",").map{ |el| el.to_i - 1 }.reverse
    end

    def valid_pos(p)
      p.length == 2 && p[0].between?(0, @board.width - 1) && p[1].between?(0, @board.height - 1)
    end

    def get_key
      begin
        system("stty raw -echo")
        str = STDIN.getc
      ensure
        system("stty -raw echo")
      end
      str.chr
    end

    def move_cursor(dir)
      pos = get_cursor
      self.board[pos].cursor = false

      case dir
      when 'a'
        pos[1] -= 1 unless pos[1] <=0
      when 's'
        pos[0] += 1 unless pos[0] >= (self.board.height - 1)
      when 'd'
        pos[1] += 1 unless pos[1] >= (self.board.width - 1)
      when 'w'
        pos[0] -= 1 unless pos[0] <= 0
      end

      p pos
      self.board[pos].cursor = true
    end

    def get_cursor
      self.board.tiles.each_with_index do |row, i|
        row.each_with_index do |col, j|
          if col.cursor
            return [i, j]
          end
        end
      end
    end

end

class Tile

  UNEXPLORED = "\u2588".encode('utf-8')
  INTERIOR = "_"
  FLAGGED = "\u2690".encode('utf-8')
  BOMBED = "\u2735".encode('utf-8')

  DELTAS = [[0, 1], [0, -1], [1, 1], [1, 0],
            [1, -1], [-1, 0], [-1, -1], [-1, 1]]

  attr_accessor :piece, :bomb, :pos, :cursor
  attr_reader :board

  def initialize(pos = [], board)
    @piece = UNEXPLORED
    @pos = pos
    @board = board
    @bomb = false
    @cursor = false
  end

  def is_bomb?
    bomb
  end

  def flag
    self.piece = FLAGGED
  end

  def reveal
    if self.is_bomb?
      self.piece   = BOMBED
    else
      n = neighbor_bomb_count

      if n > 0
        self.piece = n.to_s
      elsif self.piece == UNEXPLORED
        ####DEBUG
        #self.board.display
        # debugger

        self.piece = INTERIOR
        neighbors.each do |neighbor|
          next unless neighbor.piece == UNEXPLORED
          #puts "#{neighbor.pos}"
          neighbor.reveal
        end
      end
    end
    nil
  end

  private

    def neighbors
      arr = []

      DELTAS.each do |rpos|
        x = self.pos[0] + rpos[0]
        y = self.pos[1] + rpos[1]
        if x.between?(0,self.board.width - 1) && y.between?(0,self.board.height - 1)
          arr << self.board[[x,y]]
        end
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

  CURSOR = "\u25C8"

  attr_accessor :tiles, :width, :height

  def initialize(board_size = "small")
    @width, @height = 8 , 8 if board_size.downcase == "small"
    @tiles = Array.new(@height) { Array.new(@width) {Tile.new([], self)} }
    #debugger
    initialize_tiles
  end

  def [](pos)
    self.tiles[ pos[0] ][ pos[1] ]
  end

  def display
    puts self.to_s
  end

  def cheat
    puts
    self.tiles.each_with_index do |row, i|
      row.each_with_index do |col, j|
        p = Tile::INTERIOR
        p = Tile::BOMBED if self.tiles[i][j].is_bomb?
        putc p
        putc " "
      end
      putc "\n"
    end
  end


  def to_s
    s = ""
    self.tiles.each_with_index do |row, i|
      row.each_with_index do |col, j|
        if self[[i,j]].cursor
          s += CURSOR + " "
        else
          s += self.tiles[i][j].piece + " "
        end
      end
      s += "\n"
    end
    s
  end


  private

    def initialize_tiles
      self.tiles.each_with_index do |row, i|
        row.each_with_index do |col, j|
          self.tiles[i][j].pos = [i, j]
        end
      end

      num_bombs = 0
      until num_bombs == 10
        tile = self.tiles.sample.sample
        unless tile.is_bomb?
          tile.bomb = true
          num_bombs += 1
        end
      end

      self.tiles[0][0].cursor = true
    end

end

m = MineSweeper.new
m.play(ARGV)
