class TurnResult
  NO_CARDS = 'ran out of cards'
  EMPTY_DECK = 'the deck is empty'
  GO_AGAIN = 'can go again'
  BOOK = 'made a book with four'
  DISQUALIFIED = 'out of the game'
  REQUEST = 'requested a'

  attr_reader :current_player, :opponent_player, :rank_requested, :cards_received_opponent

  attr_accessor :was_book_made, :card_received_deck

  def initialize(current_player:, opponent_player: nil, rank_requested: nil,
                 cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
    @current_player = current_player
    @opponent_player = opponent_player
    @rank_requested = rank_requested
    @cards_received_opponent = cards_received_opponent
    @card_received_deck = card_received_deck
    @was_book_made = was_book_made
  end

  def request_message
    return '' if opponent_player.nil? || rank_requested.nil?

    "#{current_player.name} #{REQUEST} #{rank_requested} from #{opponent_player.name}."
  end

  def to_s
    "current_player: #{current_player.name}, opponent: #{opponent_player.name}, rank_requested #{rank_requested}, cards_received_opponent.length #{cards_received_opponent.length} card_received_deck: #{card_received_deck}, was_book_made #{was_book_made}"
  end

  def go_again?
    (!rank_received.nil? && rank_received == rank_requested) || was_book_made == true
  end

  def rank_received
    if went_fish? && card_received_deck
      card_received_deck.rank
    elsif !cards_received_opponent.empty?
      cards_received_opponent.first.rank
    else
      nil
    end
  end

  private

  def out_of_cards_message
    out_of_game_message
  end

  def player_out_of_cards?
    opponent_player.nil?
  end

  def give_message
    card_word = 'card'
    card_word += 's' unless cards_received_opponent.length == 1
    "#{opponent_player.name} gave #{cards_received_opponent.length} #{card_word} to #{current_player.name}."
  end

  def draw_deck_message
    if card_received_deck.nil?
      "#{current_player.name} tried to fish, but #{EMPTY_DECK}."
    else
      "#{current_player.name} drew a card from the deck."
    end
  end

  def book_message
    "#{current_player.name} #{BOOK} #{rank_received}s!"
  end

  def out_of_game_message
    "#{current_player.name} #{NO_CARDS} and #{EMPTY_DECK}. #{current_player.name} is #{DISQUALIFIED}."
  end

  def book_made?
    !!was_book_made
  end

  def went_fish?
    cards_received_opponent.empty?
  end
end
