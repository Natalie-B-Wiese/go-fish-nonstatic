require 'sinatra'
require_relative 'lib/game'
require_relative 'lib/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
  end
end
