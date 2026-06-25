require 'sinatra'
require_relative 'lib/go_fish/game'
require_relative 'lib/go_fish/player'
require 'sinatra/contrib/all'
require 'rack/contrib'

class Server < Sinatra::Base
  register Sinatra::RespondWith
  use Rack::JSONBodyParser

  enable :sessions

  def self.game
    @@game ||= Game.new
  end

  def self.api_keys
    @@api_keys ||= {}
  end

  def self.reset!
    @@game = nil
    @@api_keys = nil
  end

  get '/' do
    if authenticated?(session[:api_key])
      if self.class.game.started?
        if self.class.game.game_over?
          redirect '/game-over'
        else
          redirect '/game'
        end
      else
        redirect '/lobby'
      end
    else
      slim :login
    end
  end

  post '/reset' do
    self.class.reset!
    redirect '/'
  end

  get '/game' do
    respond_to do |f|
      f.html do
        if authenticated?(session[:api_key]) && self.class.game.started? && !self.class.game.game_over?
          slim :game, locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key],
                                game: self.class.game }
        else
          redirect '/'
        end
      end

      f.json do
        authenticate!
        # TODO: perhaps handle case where game isn't started?
        game = self.class.game

        game.data(current_bot_player).to_json
      end
    end
  end

  get '/game-over' do
    if authenticated?(session[:api_key]) && self.class.game.started? && self.class.game.game_over?
      slim :game_over,
           locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key], game: self.class.game }
    else
      redirect '/'
    end
  end

  def add_player(name, api_key)
    session[:api_key] = api_key

    self.class.api_keys[api_key] = name
    self.class.game.add_player(name)
  end

  post '/join' do
    name = params[:name] || JSON.parse(request.body.read)['name']
    api_key = Base64.urlsafe_encode64("#{name}:#{(Time.now.to_f * 1000).to_i}")

    add_player(name, api_key)

    respond_to do |f|
      f.html { redirect '/lobby' }

      f.json { { 'api_key' => api_key }.to_json }
    end
  end

  post '/start' do
    # TODO: prevent game from starting multiple times?
    self.class.game.start
    redirect '/game'
  end

  # this only happens for the bot
  post '/game' do
    respond_to do |f|
      f.json do
        authenticate!

        # TODO: perhaps handle case where bot is out of cards?
        rank = params[:rank]
        opponent_name = params[:player]

        request_card(opponent_name, rank)

        self.class.game.data(current_bot_player).to_json
      end
    end
  end

  def authenticate!
    halt 401 unless authenticated?
  end

  def auth
    Rack::Auth::Basic::Request.new(request.env)
  end

  # if api_key is nil, it will treat it like a bot
  def authenticated?(api_key = nil)
    if api_key.nil?
      return false unless auth.provided? && auth.basic?

      api_key = auth.username
    end

    self.class.api_keys.key?(api_key)
  end

  post '/request-card' do
    return redirect '/' unless authenticated?(session[:api_key])
    return redirect if self.class.api_keys[session[:api_key]] != self.class.game.current_player.name

    opponent_name = params[:opponent_name]
    request_rank = params[:rank]
    request_card(opponent_name, request_rank)
    redirect '/game'
  end

  post '/take-deck-card' do
    return redirect '/' unless authenticated?(session[:api_key])
    return redirect if self.class.api_keys[session[:api_key]] != self.class.game.current_player.name
    return redirect unless self.class.game.current_player.out_of_cards?

    turn_result = self.class.game.request_deck_card
    self.class.game.add_turn_result_to_feed(turn_result)
    self.class.game.switch_turn unless turn_result.go_again?

    redirect '/game'
  end

  get '/lobby' do
    if self.class.game.started? || !authenticated?(session[:api_key])
      redirect '/'
    else
      slim :lobby,
           locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key], game: self.class.game }
    end
  end

  def current_bot_player
    auth = Rack::Auth::Basic::Request.new(request.env)

    return nil unless auth.provided? && auth.basic?

    api_key = auth.username
    name = self.class.api_keys[api_key]

    self.class.game.player_by_name(name)
  end

  private

  def request_card(opponent_name, request_rank)
    opponent_player = self.class.game.player_by_name(opponent_name)
    self.class.game.play_turn(rank: request_rank, opponent: opponent_player)
  end
end
