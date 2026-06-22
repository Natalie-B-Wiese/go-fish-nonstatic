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
    slim :login
  end

  post '/join' do
    # generate a key using base-64 from the name
    api_key = Base64.urlsafe_encode64("#{params[:name]}:#{(Time.now.to_f * 1000).to_i}")
    session[:api_key] = api_key

    # self.class.api_keys[api_key] = params[:name]

    slim :game, locals: { name: params[:name], api_key: api_key }
  end
end
