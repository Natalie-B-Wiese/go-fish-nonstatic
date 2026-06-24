class TurnResult
  NO_CARDS = 'ran out of cards'
  EMPTY_DECK = 'The deck is empty'
  GO_AGAIN = 'can go again'
  BOOK = 'made a book with four'
  DISQUALIFIED = 'out of the game'
  REQUEST = 'requested a'
  GO_FISH = 'Go Fish'
  TAKE_DECK = 'drew a'

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
    result = ''
    if player_out_of_cards?
      result = "#{current_player.name} #{NO_CARDS}. "
      result += "#{current_player.name} #{TAKE_DECK} card from the deck. " unless card_received_deck.nil?
      result += "#{EMPTY_DECK}. #{current_player.name} is #{DISQUALIFIED}. " if deck_empty?
      result += "#{current_player.name} #{GO_AGAIN}. " if go_again?
    else
      result = "#{current_player.name} #{REQUEST} #{rank_requested} from #{opponent_player.name}."
    end

    result
  end

  def action_message
    return '' if player_out_of_cards?

    if cards_received_opponent.nil? || cards_received_opponent.empty?
      "#{GO_FISH}: #{opponent_player.name} doesn't have any #{rank_requested}s"
    else
      card_word = cards_received_opponent.length == 1 ? 'card' : 'cards'
      "#{opponent_player.name} gave #{cards_received_opponent.length} #{card_word} to #{current_player.name}."
    end
  end

  def result_message
    result = ''
    if card_received_deck
      card_str = rank_received == rank_requested ? rank_requested : 'card'
      result += "#{current_player.name} #{TAKE_DECK} #{card_str} from the deck. "
    end

    result += "#{current_player.name} #{GO_AGAIN}. " if go_again?
    result += "#{current_player.name} #{BOOK} #{rank_received}s!" if book_made?

    result
  end

  def go_again?
    (!rank_received.nil? && rank_requested.nil?) || ((!rank_received.nil? || was_book_made == true) && rank_received == rank_requested)
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

  def deck_empty?
    !cards_received_opponent.empty? || card_received_deck.nil?
  end

  def player_out_of_cards?
    opponent_player.nil?
  end

  def book_made?
    !!was_book_made
  end

  def went_fish?
    cards_received_opponent.empty?
  end
end
