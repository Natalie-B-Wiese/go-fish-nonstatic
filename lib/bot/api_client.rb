require 'httparty'
require 'base64'
require 'json'

class Bot
  class APIClient
    include HTTParty

    def initialize(url)
      self.class.base_uri url
      self.api_key = nil
    end

    def joined? = !api_key.nil?

    def join(name)
      response = post('/join', body: { name: })
      self.api_key = response['api_key']
      api_key
    end

    def game_state
      response = get('/game')
      JSON.parse(response.body)
    end

    def take_turn(move)
      response = post('/game', body: { rank: move[:rank], player: move[:target] })
      JSON.parse(response.body)
    end

    private

    attr_accessor :api_key

    def get(path)
      self.class.get(path, headers: authenticated_headers)
    end

    def post(path, body: nil)
      options = { headers: authenticated_headers }
      options[:body] = body.to_json if body
      self.class.post(path, options)
    end

    def json_headers
      {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end

    def authenticated_headers
      return json_headers unless api_key

      encoded = Base64.encode64("#{api_key}:X").strip
      json_headers.merge('Authorization' => "Basic #{encoded}")
    end
  end
end
