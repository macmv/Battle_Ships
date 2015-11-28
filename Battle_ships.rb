#! /usr/local/bin/ruby

# \   /  /---\  |      |      \              /  /---\  |\    | | | | 
#  \ /  |     | |      |       \            /  |     | | \   | | | | 
#   |   |     | |      |        \    /\    /   |     | |  \  | | | | 
#   |   |     | |      |         \  /  \  /    |     | |   \ | | | | 
#   |    \---/   \----/           \/    \/      \---/  |    \| . . . 

# [blue] = miss
# [red ] = hit

# [yellow] = ship
# [green ] = oponent guess
# [red   ] = sunk ship

# Things to add:
# check see where other player missed on bottom board
# check change X's to circles
# check don't allow geussing twice in same place
# check invalid loc deellying with
# check at the begining, show how many boats are left
# check prevent ships from over lapping
# _____ tell players if a ship got sunk
# _____ tell player if they win
# _____ add AI

# 3 = Destroyer
# 4 = Cruiser
# 5 = Battleship

require "colorize"
require "socket"

class ShipSeg

  attr_accessor :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end
end

class Ship

  def initialize(x, y, type)
    if type == "Destroyer"
      @length = 3
    elsif type == "Cruiser"
      @length = 4
    elsif type == "Battleship"
      @length = 5
    else
      raise "type is not valid"
    end
    @x = x
    @y = y
    @type = type
    @segments = [Ship_seg.new(x, y)]
  end

  def add_seg(x, y)
    @segments.push Ship_seg.new(x, y)
  end
end

class Board

  def initialize
    @ships = []
    @boats_left = {3 => 3, 4 => 2, 5 => 1}
    @top_board = []
    @bottom_board = []

    10.times do
      new_arr = []
      10.times do
        new_arr.push " "
      end
      @top_board.push new_arr
    end

    10.times do
      new_arr = []
      10.times do
        new_arr.push " "
      end
      @bottom_board.push new_arr
    end
  end

  def new_ship(x, y, direction, length)
    puts length
    if length == 3
      ship_num = 0
      @ships.each do |ship|
        if ship.length - 1 == 3
          ship_num += 1
        end
      end
      if ship_num >= 3
        return "You can't have more than 3 3 lengths".red
      end 
    elsif length == 4
      ship_num = 0
      @ships.each do |ship|
        if ship.length - 1 == 4
          ship_num += 1
        end
      end
      if ship_num >= 2
        return "You can't have more than 2 4 lengths".red
      end
    elsif length == 5
      @ships.each do |ship|
        if ship.length - 1 == 5
          return "You can't have more than 1 5 lengths".red
        end
      end
    else
      return "Ships have to be 3, 4 or 5 long".red
    end

    @boats_left[length] -= 1

    if direction == "up"
      plus_y = -1
      plus_x = 0
    elsif direction == "down"
      plus_y = 1
      plus_x = 0
    elsif direction == "right"
      plus_y = 0
      plus_x = 1
    elsif direction == "left"
      plus_y = 0
      plus_x = -1
    end
    
    new_ship = [ShipSeg.new(x, y)]

    (length - 1).times do |i|
      if new_ship[i].x < 0 || new_ship[i].x >= 10 || new_ship[i].y < 0 || new_ship[i].y >= 10
        return "That ship goes off the board".red
      elsif @bottom_board[new_ship[i].y][new_ship[i].x] != " "
        return "That ship overlaps another one".red
        @boats_left[length] += 1
      end

      new_ship.push ShipSeg.new new_ship[i].x + plus_x, new_ship[i].y + plus_y
    end

    new_ship.each do |seg|
      @bottom_board[seg.y][seg.x] = "gray"
    end

    if length == 3
      ship_name = "Destroyer"
    elsif length == 4
      ship_name = "Cruiser"
    else
      ship_name = "Battleship"
    end

    new_ship.unshift ship_name

    @ships.push new_ship

    return true
  end

  def hit(x, y)
    @top_board[y][x] = "x"
  end

  def miss(x, y)
    @top_board[y][x] = "o"
  end

  def draw_board
    puts "\033[2J\033[0;0f"
    puts "    A   B   C   D   E   F   G   H   I   J   ".magenta
    @top_board.each_with_index do |row, row_num|
      puts "  -----------------------------------------".magenta
      next_row = row_num.to_s.magenta
      row.each do |letter|
        next_row += " |".magenta
        if letter == "o"
          next_row += " ●".blue
        elsif letter == "x"
          next_row += " ●".red
        else
          next_row += "  "
        end
      end
      next_row += " |".magenta
      puts next_row
    end
    puts "  -----------------------------------------".magenta
    puts
    puts "    A   B   C   D   E   F   G   H   I   J   ".magenta
    @bottom_board.each_with_index do |row, row_num|
      puts "  -----------------------------------------".magenta
      next_row = row_num.to_s.magenta
      row.each do |letter|
        next_row += " |".magenta
        if letter == "gray"
          next_row += " ●".yellow
        elsif letter == "red"
          next_row += " ●".red
        elsif letter == "green"
          next_row += " ●".green
        else
          next_row += "  "
        end
      end
      next_row += " |".magenta
      puts next_row
    end
    puts "  -----------------------------------------".magenta
  end

  def draw_boats_left
    print "Boats Left: ".light_blue
    @boats_left[3].times do
      print "3 ".light_blue
    end
    @boats_left[4].times do
      print "4 ".light_blue
    end
    @boats_left[5].times do
      print "5 ".light_blue
    end
    puts
  end

  def add_miss(x, y)
    @bottom_board[y][x] = "green"
  end

  def did_guess_at(x, y)
    @top_board[y][x] != " "
  end

  def hit_my_ship(x, y)
    if @bottom_board[y][x] == "gray"
      @bottom_board[y][x] = "red"
      @ships.each_with_index do |ship, ship_num|
        ship.each_with_index do |ship_seg, ship_seg_num|
          if ship_seg_num== 0
            ship_name = ship_seg
            next
          end
          if ship_seg.x == x && ship_seg.y == y
            ship.delete_at ship_seg_num
            if ship.length == 0
              @ships.delete_at ship_num
              if @ships.length == 0
                return "other player won"
              end
              return "sunk ship #{ship_name}"
            end
          end
        end
      end
      "hit"
    else
      "miss"
    end
  end
end

def print_you_won
  puts " \\ / /\\ | |   \\    / /\\ |\\ | | | | |".green
  puts "  |  \\/ \\_/    \\/\\/  \\/ | \\| . . . .".green
end

def my_turn(other_player, board)
  puts "Your turn".light_blue
  while true
    guess = gets.chomp.downcase
    if (guess =~ /^[a-j][0-9]$/) == 0
      guess_arr = [$letters[guess.split("")[0]], guess.split("")[1].to_i]
      if board.did_guess_at(guess_arr[0], guess_arr[1])
        board.draw_board
        puts "You already guessed there".red
      else
        other_player.puts guess
        break
      end
    else
      board.draw_board
      puts "Please enter a valid corrodinate".red
    end
  end

  did_hit = other_player.gets.chomp

  if did_hit == "hit"
    board.hit(guess_arr[0], guess_arr[1])
    board.draw_board
    puts "Hit!".light_blue
  elsif (did_hit =~ /sunk ship (Destroyer|Cruiser|Battleship)/)
    board.hit(guess_arr[0], guess_arr[1])
    board.draw_board
    puts "You sunk their #{did_hit.split(" ")[2]}!".light_blue
  elsif did_hit == "you won"
    board.hit(guess_arr[0], guess_arr[1])
    board.draw_board
    print_you_won
    sleep 2
    exit
  else
    board.miss(guess_arr[0], guess_arr[1])
    board.draw_board
    puts "Miss".light_blue
  end
end

def opponents_turn(other_player, board)
  puts "Oponnent's turn".light_blue

  other_player_guess = other_player.gets.chomp
  other_player_guess = other_player_guess.split("")
  other_player_guess[0] = $letters[other_player_guess[0]]
  other_player_guess[1] = other_player_guess[1].to_i

  did_hit = board.hit_my_ship(other_player_guess[0], other_player_guess[1])

  if did_hit == "miss"
    board.add_miss(other_player_guess[0], other_player_guess[1])
  end

  board.draw_board

  if did_hit == "hit"
    puts "Oponnent Hit!".red
    other_player.puts "hit"
  elsif did_hit == "sunk ship"
    puts "Oponnent Sunk Ship!!!!".red
    other_player.puts "sunk ship"
  elsif did_hit == "other player won"
    puts "Sorry, you lost".red
    other_player.puts "you won"
    sleep 2
    exit
  else
    puts "Oponnent Miss".light_blue
    other_player.puts "miss"
  end
end

while true
  puts "Are you player 1 or 2? (1 or 2)".light_blue

  player = gets.chomp

  if player == "1"
    am_player_1 = true
    break
  elsif player == "2"
    am_player_1 = false
    break
  else
    puts "Please enter 1 or 2".red
  end
end

while true
  puts "Please enter the port number".light_blue
  port = gets.chomp.to_i
  if port > 65535
    puts "Please enter a port number that is less than or equal to 65535".red
  elsif port < 1024
    puts "Please enter a port number that is greater than or equal to 1024".red
  else
    break
  end
end

if am_player_1
  server = TCPServer.open(port)
  puts "Waiting for Player 2 to connect...".light_blue
  other_player = server.accept
else
  while true
    puts "Please enter IP adress of Player 1".light_blue
    hostname = gets.chomp.downcase
    if hostname == "cedar"
      hostname = "10.0.1.4"
    end
    begin
      other_player = TCPSocket.open(hostname, port)
      break
    rescue
      puts "Cannot connect to #{hostname}".red
    end
  end
end

$letters = {"a" => 0, "b" => 1, "c" => 2, "d" => 3, "e" => 4, "f" => 5, "g" => 6, "h" => 7, "i" => 8, "j" => 9}

nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

board = Board.new

puts "Do you nead instructions? (y or n)".light_blue

answer = gets.chomp.downcase

if answer == "y"
  puts "  At the begining of the game, you will be asked to place your ships.\n" +
  "  You have 3 3 lengths, 2 4s, and 1 5 length. Once you are done placing your ships, if the other player is done to the game will start. If not, you will nead to wait.\n" +
  "  When the game starts, of you are player one, a message that says \"Your turn\" will pop up. Enter the corrodinates of you guess, like A6, for example. a message will come back saying \"Hit!\" or \"Miss\".\n" +
  "  Then it will say, \"Oponnent's turn\". Just sit and wait for the oponnent to guess. When they do, a message saying if he hit one of you ships or not will pop up.\n" +
  "  If you are player 2, first it will say \"Oponnent's turn\", then it will say \"Your turn\"."
  gets
end

board.draw_board

6.times do
  puts "Please enter the corrodinates of you ship. Enter one on each line, and a corrodinate should look like this: A6 up 3, for example. That would mean, A6, going up 3 spaces. You can use up, down right or left.".light_blue
  board.draw_boats_left
  while true
    while true
      new_ship_loc = gets.chomp.downcase
      if (new_ship_loc =~ /[a-j][0-9] (left|right|up|down) [3-5]/) == 0
        new_ship_loc = new_ship_loc.split(" ")
        break
      else
        board.draw_board
        puts "Please enter a valid corrodinate".red
      end
    end

    board.draw_board

    # example ship: A6 right 3

    x = $letters[new_ship_loc[0].split("")[0]]
    y = new_ship_loc[0].split("")[1].to_i
    direction = new_ship_loc[1]
    length = new_ship_loc[2].to_i

    return_val = board.new_ship(x, y, direction, length)

    if return_val == true
      board.draw_board
      break
    else
      puts return_val
    end
  end
end

puts "Ready to start game. Please wait for #{am_player_1 ? 'player 2' : 'player 1'} to finish placing their ships.".light_blue

other_player.puts "ready"
other_player.gets

is_my_turn = am_player_1

while true
  if is_my_turn
    my_turn(other_player, board)
  else
    opponents_turn(other_player, board)
  end
  is_my_turn = !is_my_turn
end