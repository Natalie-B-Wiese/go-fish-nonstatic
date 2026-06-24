require 'sinatra'
require_relative 'lib/go_fish/game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
  end

  def self.api_keys
    @@api_keys ||= {}
  end

  def self.reset!
    @@game = nil
  end

  get '/' do
    if authenticated?(session)
      if self.class.game.started?
        redirect '/game'
      else
        redirect '/lobby'
      end
    else
      slim :login
    end
  end

  get '/game' do
    if authenticated?(session) && self.class.game.started?
      slim :game,
           locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key], game: self.class.game }
    else
      redirect '/'
    end
  end

  post '/join' do
    # generate a key using base-64 from the name
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{(Time.now.to_f * 1000).to_i}")
    session[:api_key] = api_key

    self.class.api_keys[api_key] = params[:name]
    self.class.game.add_player(params[:name])

    redirect '/lobby'
  end

  post '/start' do
    # TODO: prevent game from starting multiple times?
    self.class.game.start
    redirect '/game'
  end

  def authenticate!
    # return a status code of 403
    halt 401
  end

  def authenticated?(session)
    !!self.class.api_keys[session[:api_key]]
  end

  post '/request-card' do
    return redirect '/' unless authenticated?(session)
    return redirect if self.class.api_keys[session[:api_key]] != self.class.game.current_player.name

    opponent_name = params[:opponent_name]
    request_rank = params[:rank]
    opponent_player = self.class.game.player_by_name(opponent_name)

    self.class.game.play_turn(rank: request_rank, opponent: opponent_player)
    redirect '/game'
  end

  post '/take-deck-card' do
    return redirect '/' unless authenticated?(session)
    return redirect if self.class.api_keys[session[:api_key]] != self.class.game.current_player.name
    return redirect unless self.class.game.current_player.out_of_cards?

    turn_result = self.class.game.request_deck_card
    self.class.game.add_turn_result_to_feed(turn_result)
    self.class.game.switch_turn unless turn_result.go_again?

    redirect '/game'
  end

  get '/lobby' do
    if self.class.game.started? || !authenticated?(session)
      redirect '/'
    else
      slim :lobby,
           locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key], game: self.class.game }
    end
  end
end
