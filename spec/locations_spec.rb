require_relative '../server'
require 'sinatra/contrib/all'

describe Server, type: :request do
  include Rack::Test::Methods

  let!(:app) { Server.new }

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
end
