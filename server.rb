require 'sinatra'
require_relative 'lib/go_fish/game'
require_relative 'lib/go_fish/player'

class Server < Sinatra::Base
  enable :sessions
  def self.game
    @@game ||= Game.new
  end
end
