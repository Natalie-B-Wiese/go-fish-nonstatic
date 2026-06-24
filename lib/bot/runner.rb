# Usage: ruby lib/bot_runner.rb [server_url]
# Examples:
#   ruby lib/bot_runner.rb                          # defaults to localhost:9292
#   ruby lib/bot_runner.rb http://localhost:9292     # explicit URL
#   ruby lib/bot_runner.rb http://10.0.0.5:9292     # connect to another machine

require_relative 'bot'

url = ARGV[0] || 'http://localhost:9292'
bot = Bot.new(url: url)

loop do
  bot.try_to_join unless bot.in_game?
  bot.try_to_take_turn if bot.in_game?
  break if bot.game_over?

  sleep 0.5
end
