require 'sinatra'
require_relative 'lib/go_fish/game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
  end

  def self.reset!
    @@game = nil
  end

  get '/' do
    slim :login
  end

  post '/submit' do
    slim :game, locals: { name: params[:name] }
  end
end
