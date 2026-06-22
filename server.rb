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
    if self.class.api_keys[session[:api_key]]
      redirect '/game'
    else
      slim :login
    end
  end

  get '/game' do
    slim :game,
         locals: { name: self.class.api_keys[session[:api_key]], api_key: session[:api_key], game: self.class.game }
  end

  post '/join' do
    # generate a key using base-64 from the name
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{(Time.now.to_f * 1000).to_i}")
    session[:api_key] = api_key

    self.class.api_keys[api_key] = params[:name]
    self.class.game.add_player(params[:name])

    redirect '/game'
  end
end
