require_relative '../lib/go_fish/turn_result'
require_relative '../lib/go_fish/player'
require_relative '../lib/card'

# initialize(current_player:, opponent_player: nil, rank_requested: nil,
#                  cards_received_opponent: [], card_received_deck: nil, was_book_made: false)
describe TurnResult do
  let(:current_player_name) { 'Jeff' }
  let(:current_player) { Player.new(current_player_name) }

  let(:opponent_name) { 'Bob' }
  let(:opponent_player) { Player.new(opponent_name) }

  let(:rank_requested) { '4' }
  let(:other_rank) { '3' }

  describe '#request_message' do
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
  end

  describe '#action_message' do
    context 'when player made a request and receives one card from opponent' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                       rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')])
      end

      it 'returns receive from opponent message' do
        result = turn_result.action_message
        expect(result).to match(/#{opponent_name}.*1 card.*#{current_player_name}/)
      end
    end

    context 'when player made a request and receives one card from opponent' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                       rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades'), Card.new(rank_requested, 'Hearts')])
      end

      it 'returns receive from opponent message' do
        result = turn_result.action_message
        expect(result).to match(/#{opponent_name}.*2 cards.*#{current_player_name}/)
      end
    end

    context 'when player made a request and does not receive a card from opponent' do
      let(:turn_result) do
        TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                       rank_requested: rank_requested)
      end

      it 'returns go fish message' do
        result = turn_result.action_message
        expect(result).to match(/#{TurnResult::GO_FISH}.*#{opponent_name}.* #{rank_requested}/)
      end
    end
  end

  describe '#result_message' do
    context 'when player receives requested card from opponent' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')])
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'does not return card draw from deck message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{TurnResult::TAKE_DECK}/)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{TurnResult::BOOK}/)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')], was_book_made: true)
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'does not return card draw from deck message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{TurnResult::TAKE_DECK}/)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{TurnResult::BOOK}/)
        end
      end
    end

    context 'when player receives requested card from deck' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, card_received_deck: Card.new(rank_requested, 'Spades'))
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{TurnResult::BOOK}/)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, card_received_deck: Card.new(rank_requested, 'Spades'), was_book_made: true)
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{TurnResult::BOOK}/)
        end
      end
    end

    context 'when player does not receive requested card' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, card_received_deck: Card.new(other_rank, 'Spades'))
        end

        it 'returns card draw from deck message' do
          result = turn_result.result_message
          expect(result).to match(/#{TurnResult::TAKE_DECK}/)
        end

        it 'does not return go again message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{TurnResult::BOOK}/)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          TurnResult.new(current_player: current_player, opponent_player: opponent_player,
                         rank_requested: rank_requested, card_received_deck: Card.new(other_rank, 'Spades'), was_book_made: true)
        end

        it 'does not return go again message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{current_player_name}.*#{TurnResult::GO_AGAIN}/)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{TurnResult::BOOK}/)
        end
      end
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
