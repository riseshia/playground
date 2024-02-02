require 'discordrb'

bot = Discordrb::Bot.new token: ENV["DISCORD_BOT_TOKEN"]

puts "Starting bot..."

prefix = "<@#{bot.profile.id}> "
bot.message(start_with: prefix) do |event|
  command = event.message.content.split(prefix)[1]

  puts "Command: #{command}"
  case command
  when "start"
    event.respond "서버를 시작합니다."
  when "stop"
    event.respond "서버를 정지합니다."
  else
    event.respond "Help: start | stop"
  end
end

bot.run
