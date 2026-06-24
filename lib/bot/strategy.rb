class Bot
  class Strategy
    RANKS = %w[A 2 3 4 5 6 7 8 9 10 J Q K].freeze

    def choose_move(players:, hand:, bot_name:)
      opponents = other_players(players:, bot_name:)
      { target: opponents.sample, rank: ranked_by_count(hand).first }
    end

    def record_round_results(results)
    end

    private

    def other_players(players:, bot_name:)
      players
        .map { |p| p['name'] }
        .reject { |n| n == bot_name }
    end

    def hand_ranks(hand)
      hand.map { |c| c['rank'] }
    end

    def ranked_by_count(hand)
      hand_ranks(hand).tally.sort_by { |_rank, count| -count }.map(&:first)
    end
  end
end
