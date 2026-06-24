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
end
