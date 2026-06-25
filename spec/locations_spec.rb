require_relative '../server'
require 'sinatra/contrib/all'
require_relative '../lib/go_fish/game'

describe Server, type: :request do
  include Rack::Test::Methods

  let!(:app) { Server.new }

  def create_and_join_bot(name)
    post '/join', { 'name' => name }.to_json,
         { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

    api_key = JSON.parse(last_response.body)['api_key']
    encoded = Base64.encode64("#{api_key}:X").strip
    "Basic #{encoded}"
  end

  describe 'POST /join' do
    # {
    #   "id": "file:/join.json#",
    #   "type": "object",
    #   "required": [
    #     "api_key"
    #   ],
    #   "properties": {
    #     "api_key": {
    #       "type": "string"
    #     }
    #   }
    # }

    it 'returns a response matching the join schema' do
      post '/join', { 'name' => 'Bot' }.to_json,
           { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
      expect(last_response).to be_ok
      expect(last_response).to match_json_schema('join')
    end

    # game get and game post
  end

  # "required": [
  #   "turn_index",
  #   "players",
  #   "hand",
  #   "round_results"
  # ]
  describe 'GET /game' do
    context 'when not authenticated' do
      it 'prevents unauthorized bots' do
        get '/game', {}, { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }
        expect(last_response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      before do
        post '/join', { 'name' => 'Bot' }.to_json,
             { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }

        Server.game.start

        api_key = JSON.parse(last_response.body)['api_key']
        encoded = Base64.encode64("#{api_key}:X").strip

        get '/game', {},
            { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'HTTP_AUTHORIZATION' => "Basic #{encoded}" }
      end

      it 'allows authorized bots' do
        expect(last_response).to be_ok
      end

      it 'returns a response matching the game schema' do
        expect(last_response).to match_json_schema('game')
      end
    end
  end

  describe 'POST /game' do
    let!(:bot1_authorization) { create_and_join_bot('Bot 1') }
    let!(:bot2_authorization) { create_and_join_bot('Bot 2') }

    before do
      Server.game.start

      # from api_client.rb:
      # response = post('/game', body: { rank: move[:rank], player: move[:target] })

      post '/game', { 'rank' => 'A', 'player' => 'Bot 2' }.to_json,
           { 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json',
             'HTTP_AUTHORIZATION' => "#{bot1_authorization}" }
    end

    it 'does not throw an error' do
      expect(last_response).to be_ok
    end

    it 'returns a response matching the turn result schema' do
      expect(last_response).to match_json_schema('round_result')
    end

    # Bot plays a round: sends rank + target player
    it 'preforms a move' do
      expect(Server.game.players[0].card_count).not_to eq Game::SMALL_GAME_CARDS
    end
  end
end
