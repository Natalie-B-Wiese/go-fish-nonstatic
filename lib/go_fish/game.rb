require_relative '../deck'
require_relative 'turn_result'
require_relative 'book'
require_relative 'player'

class Game
  SMALL_GAME_CARDS = 7
  BIG_GAME_CARDS = 5
  BOOKS_TO_WIN = (Card::SUITS.length * Card::RANKS.length) / Book::SIZE

  attr_reader :players, :deck, :inputs, :feed

  attr_accessor :current_player_index, :go_again, :is_started

  def initialize(players = [])
    @players = players
    @deck = Deck.new
    @current_player_index = 0
    @is_started = false
    @feed = []
  end

  def player_by_name(player_name)
    players[players.index { |player| player.name == player_name }]
  end

  def opponent_players(player)
    players - [player]
  end

  def add_player(player_name)
    player = Player.new(player_name)
    @players.push(player)
  end

  def add_turn_result_to_feed(turn_result)
    feed.push(turn_result)
  end

  def started?
    !!is_started
  end

  def game_over?
    book_count == BOOKS_TO_WIN
  end

  def current_player
    players[current_player_index]
  end

  # the player currently in the lead
  def winning_player
    winning_players = players_with_most_books

    return winning_players[0] if winning_players.length == 1

    player_with_biggest_value_book(winning_players)
  end

  def start
    deck.shuffle
    if players.length <= 3
      deal_cards_to_players(SMALL_GAME_CARDS)
    else
      deal_cards_to_players(BIG_GAME_CARDS)
    end
    self.is_started = true
  end

  def play_turn(rank:, opponent:)
    cards_taken_from_opponent = opponent.take_cards_with_rank(rank)
    turn_result = TurnResult.new(current_player: current_player, opponent_player: opponent, rank_requested: rank,
                                 cards_received_opponent: cards_taken_from_opponent)

    if cards_taken_from_opponent.empty?
      request_deck_card(turn_result)
    else
      current_player.add_cards(cards_taken_from_opponent)
    end

    if turn_result.rank_received
      book_made = current_player.try_make_book(turn_result.rank_received)
      turn_result.was_book_made = true if book_made
    end

    switch_turn unless turn_result.go_again?

    add_turn_result_to_feed(turn_result)

    turn_result
  end

  def opponent_options_s
    opponents_with_id_array = []
    players.each_with_index do |player, index|
      next if index == current_player_index

      opponents_with_id_array.push((index + 1).to_s + ': ' + player.name)
    end

    opponents_with_id_array.join(', ')
  end

  def request_deck_card(turn_result = TurnResult.new(current_player: current_player))
    unless deck.empty?
      card_taken = deck.take_top_card
      turn_result.card_received_deck = card_taken
      current_player.add_card(card_taken)
    end

    turn_result
  end

  def switch_turn
    self.current_player_index += 1
    self.current_player_index = 0 if current_player_index >= players.length
  end

  private

  def deal_cards_to_players(num_cards_to_deal)
    num_cards_to_deal.times do
      players.each do |player|
        player.add_card(deck.take_top_card)
      end
    end
  end

  def book_count
    players.inject(0) { |sum, player| sum + player.book_count }
  end

  def players_with_most_books
    players.select { |player| player.book_count == most_books }
  end

  def player_with_biggest_value_book(players_array)
    players_array.max_by(&:biggest_book_value)
  end

  def most_books
    players.max_by(&:book_count).book_count
  end
end
