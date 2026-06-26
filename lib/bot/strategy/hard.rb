class Bot
  class Strategy
    class Hard < Strategy
      attr_accessor :opponent_hands

      def initialize
        @opponent_hands = {}
        self.deck = []
      end

      def choose_move(players:, hand:, bot_name:)
        opponents = other_players(players:, bot_name:)

        opponent_ranks_matching(opponents, hand_ranks(hand)).sample ||
          { target: opponents.sample, rank: pick_best_rank(hand) }
      end

      # def choose_move(players:, hand:, bot_name:)
      #   opponents = other_players(players:, bot_name:)
      #   opponent_ranks_matching(opponents, hand_ranks(hand)).sample ||
      #     { target: opponents.sample, rank: pick_best_rank(hand) }
      # end

      def record_round_results(results)
        self.opponent_hands = {}

        results.each do |result|
          record_opponent_hand_from_result(result)
        end
      end

      private

      attr_accessor :deck

      def record_opponent_hand_from_result(result)
        player_name = result['current_player']
        rank = result['rank']
        went_fishing = result['went_fishing']

        opponent_hands[player_name] = [] unless opponent_hands.key?(player_name)
        opponent_hands[player_name].push(rank) unless opponent_hands[player_name].include?(rank)

        return if went_fishing == true

        remove_rank_from_opponents(rank, player_name)
      end

      def remove_rank_from_opponents(rank, ignore_name)
        opponent_hands.each do |name, _|
          next if name == ignore_name

          opponent_hands[name] -= [rank]
        end
      end

      def pick_best_rank(hand)
        counts = hand_ranks(hand).tally
        max = counts.values.max
        counts.select { |_, c| c == max }.keys.sample
      end

      def opponent_ranks_matching(opponents, ranks)
        targets = []
        opponent_hands.each do |name, card_ranks|
          next unless opponents.include?(name)

          ranks_matching(card_ranks, ranks).each do |matching_rank|
            targets.push({ target: name, rank: matching_rank })
          end
        end

        targets
      end

      def ranks_matching(card_ranks1, card_ranks2)
        card_ranks1.select { |rank| card_ranks2.include?(rank) }
      end
    end
  end
end
