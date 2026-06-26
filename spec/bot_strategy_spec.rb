require 'spec_helper'
require_relative '../lib/bot/bot'

RSpec.describe Bot::Strategy do
  let(:bot_name) { 'Bot' }
  let(:hand) do
    [{ 'rank' => '3', 'suit' => 'H' }, { 'rank' => '5', 'suit' => 'D' }, { 'rank' => 'K', 'suit' => 'S' }]
  end
  let(:players) do
    [{ 'name' => bot_name }, { 'name' => 'Alice' }, { 'name' => 'Bob' }]
  end

  describe '#choose_move' do
    it 'returns a hash with :target and :rank' do
      move = described_class.new.choose_move(players: players, hand: hand, bot_name: bot_name)

      expect(move).to have_key(:target)
      expect(move).to have_key(:rank)
    end

    it 'never targets itself' do
      targets = 10.times.map do
        move = described_class.new.choose_move(players: players.shuffle, hand: hand.shuffle, bot_name: bot_name)
        move[:target]
      end

      expect(targets).to all(satisfy { |t| t != bot_name })
    end

    it 'picks from available opponents' do
      move = described_class.new.choose_move(players: players, hand: hand, bot_name: bot_name)

      expect(%w[Alice Bob]).to include(move[:target])
    end
  end
end

RSpec.describe Bot::Strategy::Medium do
  let(:iteration_count) { 10 }
  let(:bot_name) { 'Bot' }

  let(:hand) do
    [{ 'rank' => '3', 'suit' => 'H' }, { 'rank' => '5', 'suit' => 'D' }, { 'rank' => 'K', 'suit' => 'S' }]
  end
  let(:players) do
    [{ 'name' => bot_name }, { 'name' => 'Alice' }, { 'name' => 'Bob' }]
  end

  def expect_ignored_fallback(moves, ignored_move)
    expect(moves).not_to include(ignored_move).exactly(iteration_count).times
    expect(moves).to all(satisfy { |m| %w[3 5 K].include?(m[:rank]) && %w[Alice Bob].include?(m[:target]) })
  end

  describe '#choose_move' do
    it 'falls back to picking from the hand when no turns have been recorded' do
      move = described_class.new.choose_move(players: players, hand: hand, bot_name: bot_name)

      expect(%w[3 5 K]).to include(move[:rank])
      expect(%w[Alice Bob]).to include(move[:target])
    end

    it 'targets an opponent who successfully asked for a rank the bot holds' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => '5', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect(moves).to all(eq({ target: 'Alice', rank: '5' }))
    end

    it 'targets a rank an opponent asked for two moves ago' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => 'K', 'went_fishing' => false },
                                      { 'current_player' => 'Bob', 'rank' => '9', 'went_fishing' => true }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect(moves).to all(eq({ target: 'Alice', rank: 'K' }))
    end

    it 'ignores round results where the player went fishing' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => '5', 'went_fishing' => true }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: 'Alice', rank: '5' })
    end

    it 'ignores round results for ranks not in the bot hand' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => 'Q', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: 'Alice', rank: 'Q' })
    end

    it 'ignores round results from the bot itself' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => bot_name, 'rank' => '5', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: bot_name, rank: '5' })
    end
  end
end

RSpec.describe Bot::Strategy::Hard do
  let(:iteration_count) { 10 }
  let(:bot_name) { 'Bot' }

  let(:hand) do
    [{ 'rank' => '3', 'suit' => 'H' }, { 'rank' => '5', 'suit' => 'D' }, { 'rank' => 'K', 'suit' => 'S' }]
  end
  let(:players) do
    [{ 'name' => bot_name }, { 'name' => 'Alice' }, { 'name' => 'Bob' }]
  end

  def expect_ignored_fallback(moves, ignored_move)
    expect(moves).not_to include(ignored_move).exactly(iteration_count).times
    expect(moves).to all(satisfy { |m| %w[3 5 K].include?(m[:rank]) && %w[Alice Bob].include?(m[:target]) })
  end

  describe '#record_round_results' do
    context 'with one round result' do
      let!(:strategy) { described_class.new }
      let(:player1_name) { 'Henry' }
      let(:rank) { '5' }
      let(:round_results) do
        [
          { 'current_player' => player1_name, 'rank' => rank, 'went_fishing' => false }
        ]
      end

      before do
        strategy.record_round_results(round_results)
      end

      it 'creates a key with the player name' do
        expect(strategy.opponent_hands.key?(player1_name)).to eq true
      end

      it 'key contains that card in the hand' do
        expect(strategy.opponent_hands[player1_name]).to include rank
      end
    end

    context 'when player asks for same rank multiple times' do
      let!(:strategy) { described_class.new }
      let(:player1_name) { 'Henry' }
      let(:rank) { '5' }

      let(:round_results) do
        [
          { 'current_player' => player1_name, 'rank' => rank, 'went_fishing' => false },
          { 'current_player' => player1_name, 'rank' => rank, 'went_fishing' => true }
        ]
      end

      before do
        strategy.record_round_results(round_results)
      end

      it 'creates a key with the player name' do
        expect(strategy.opponent_hands.key?(player1_name)).to eq true
      end

      it 'does not duplicate the rank' do
        expect(strategy.opponent_hands[player1_name].length).to eq 1
      end
    end

    context 'when player asks for different ranks' do
      let!(:strategy) { described_class.new }
      let(:player1_name) { 'Henry' }
      let(:rank1) { '5' }
      let(:rank2) { '3' }

      let(:round_results) do
        [
          { 'current_player' => player1_name, 'rank' => rank1, 'went_fishing' => false },
          { 'current_player' => player1_name, 'rank' => rank2, 'went_fishing' => true }
        ]
      end

      before do
        strategy.record_round_results(round_results)
      end

      it 'creates a key with the player name' do
        expect(strategy.opponent_hands.key?(player1_name)).to eq true
      end

      it 'key contains all the cards in the hand' do
        expect(strategy.opponent_hands[player1_name]).to include rank1
        expect(strategy.opponent_hands[player1_name]).to include rank2
      end
    end
  end

  xdescribe '#choose_move' do
    it 'falls back to picking from the hand when no turns have been recorded' do
      move = described_class.new.choose_move(players: players, hand: hand, bot_name: bot_name)

      expect(%w[3 5 K]).to include(move[:rank])
      expect(%w[Alice Bob]).to include(move[:target])
    end

    it 'ignores round results from the bot itself' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => bot_name, 'rank' => '5', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: bot_name, rank: '5' })
    end

    xit 'targets an opponent who successfully asked for a rank the bot holds' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => '5', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect(moves).to all(eq({ target: 'Alice', rank: '5' }))
    end

    xit 'targets a rank an opponent asked for two moves ago' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => 'K', 'went_fishing' => false },
                                      { 'current_player' => 'Bob', 'rank' => '9', 'went_fishing' => true }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect(moves).to all(eq({ target: 'Alice', rank: 'K' }))
    end

    xit 'ignores round results where the player went fishing' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => '5', 'went_fishing' => true }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: 'Alice', rank: '5' })
    end

    xit 'ignores round results for ranks not in the bot hand' do
      strategy = described_class.new
      strategy.record_round_results([
                                      { 'current_player' => 'Alice', 'rank' => 'Q', 'went_fishing' => false }
                                    ])

      moves = iteration_count.times.map { strategy.choose_move(players: players, hand: hand, bot_name: bot_name) }

      expect_ignored_fallback(moves, { target: 'Alice', rank: 'Q' })
    end
  end
end
