class Bot
  class Strategy
    class Hard < Strategy
      attr_accessor :opponent_hands

      def initialize
        self.round_results = []

        @opponent_hands = {}
        self.deck = []
      end

      def choose_move(players:, hand:, bot_name:)
        opponents = other_players(players:, bot_name:)
        opponent_ranks_matching(opponents, hand_ranks(hand)).sample ||
          { target: opponents.sample, rank: pick_best_rank(hand) }
      end

      def record_round_results(results)
        results.each do |result|
          player_name = result['current_player']
          rank = result['rank']
          # went_fishing = result['went_fishing']

          opponent_hands[player_name] = [] unless opponent_hands.key?(player_name)
          opponent_hands[player_name].push(rank) unless opponent_hands[player_name].include?(rank)
        end

        self.round_results = results
      end

      private

      attr_accessor :round_results, :deck

      def pick_best_rank(hand)
        counts = hand_ranks(hand).tally
        max = counts.values.max
        counts.select { |_, c| c == max }.keys.sample
      end

      def opponent_ranks_matching(opponents, ranks)
        round_results.filter_map do |r|
          next if r['went_fishing']
          next unless opponents.include?(r['current_player']) && ranks.include?(r['rank'])

          { target: r['current_player'], rank: r['rank'] }
        end.uniq
      end
    end
  end
end
