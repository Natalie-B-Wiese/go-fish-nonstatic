require_relative '../lib/go_fish/turn_result'
require_relative '../lib/go_fish/player'
require_relative '../lib/card'

# initialize(current_player:, opponent_player: nil, rank_requested: nil,
#                  cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
describe TurnResult do
  describe '#request_message' do
    let(:current_player_name) { 'Jeff' }
    let(:current_player) { Player.new(current_player_name) }

    let(:opponent_name) { 'Bob' }
    let(:opponent_player) { Player.new(opponent_name) }

    let(:card_received) { Card.new('5', 'Spades') }
    let(:rank_requested) { '4' }

    context 'when player requests card from opponent' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player, opponent_player: opponent_player, rank_requested: rank_requested)
      end

      it 'returns request message' do
        result = turn_result.request_message
        expect(result).to match(/#{TurnResult::REQUEST}/)
        expect(result).to match(/#{current_player_name}.*#{opponent_name}/)
        expect(result).to match(/#{rank_requested}/)
      end
    end

    context 'when request not made' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player)
      end

      it 'returns empty string' do
        result = turn_result.request_message
        expect(result).to eq ''
      end
    end

    # current_player:, opponent_player: nil, rank_requested: nil,
    #             cards_received_opponent: [], card_received_deck: nil, was_book_made: false
    xcontext 'when opponent_player is nil, rank_requested is nil, cards_received is nil' do
      let(:turn_result) { TurnResult.new(current_player: current_player) }
      it 'returns player out of game message' do
        result = turn_result.feed_messages
        expect(result).to match(/#{TurnResult::DISQUALIFIED}/i)
      end
    end
  end
end
