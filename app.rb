require 'sinatra'
require 'slim'

get '/' do
  slim :login
end
