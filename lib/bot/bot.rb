require_relative 'api_client'
require_relative 'strategy'
require_relative 'strategy/medium'

class Bot
  NAMES = %w[Joe Hal Max Ada Eve Rex Dot Sam Ace Kit].freeze

  attr_reader :name, :strategy

  def initialize(url: 'http://localhost:9292', strategy: Strategy::Medium.new)
    @client = APIClient.new(url)
    @strategy = strategy
    @last_state_key = nil
    @last_results_count = 0
    @name = "Bot #{NAMES.sample}"
    @game_over = false
  end

  def in_game? = client.joined?

  def try_to_join
    api_key = client.join(name)
    puts "Joined as #{name} (API key: #{api_key})"
  end

  def game_over? = game_over

  def try_to_take_turn
    players, hand, turn_index, round_results, winners = parse_state(client.game_state)
    log_state_change(players:, hand:, turn_index:)
    log_opponent_results(round_results)
    strategy.record_round_results(round_results)
    return handle_game_over(winners) if winners&.any?

    take_turn(players:, hand:) if my_turn?(players:, hand:, turn_index:)
  end

  private

  attr_accessor :client, :last_state_key, :last_results_count, :game_over
  attr_writer :name, :strategy

  def parse_state(state)
    state.values_at('players', 'hand', 'turn_index', 'round_results', 'winners')
  end

  def handle_game_over(winners)
    self.game_over = true
    puts "🏁 Game over! Winner(s): #{winners.join(', ')}"
  end

  def take_turn(players:, hand:)
    move = strategy.choose_move(players:, hand:, bot_name: name)
    puts "  ▶ Asking #{move[:target]} for #{move[:rank]}..."
    result = client.take_turn(move)
    log_turn_result(result)
  end

  def my_turn?(players:, hand:, turn_index:)
    players.length >= 2 && hand.any? && current_name(players:, turn_index:) == name
  end

  def current_name(players:, turn_index:)
    players[turn_index % players.length]['name']
  end

  def log_opponent_results(round_results)
    new_results = (round_results || [])[last_results_count..]
    self.last_results_count = round_results&.length || 0
    new_results&.each { |r| puts "  ← #{r['display']}" }
  end

  def log_turn_result(state)
    results = state['round_results'] || []
    display = results.last&.dig('display')
    self.last_results_count = results.length
    puts "  ← #{display}" if display
  end

  def log_hand(hand)
    cards = hand.map { |c| "#{c['rank']}#{c['suit']}" }.join(', ')
    puts "  Hand: [#{cards}]"
  end

  def log_books(players)
    players.each do |p|
      count = p['book_count'] || 0
      next if count.zero?

      puts "  #{p['name']}: #{count} books (#{p['books'].join(', ')})"
    end
  end

  def log_state_change(players:, hand:, turn_index:)
    state_key = [turn_index, players.length, hand.length]
    return if players.empty? || state_key == last_state_key

    self.last_state_key = state_key
    marker = my_turn?(players:, hand:, turn_index:) ? ">>> MY TURN" : "    waiting"
    puts "[Turn #{turn_index}] #{marker} | Players: #{players.map { |p| p['name'] }.join(', ')} | Current: #{current_name(players:, turn_index:)}"
    log_hand(hand)
    log_books(players)
  end
end
