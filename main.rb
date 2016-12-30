#!/usr/bin/env ruby
# By Jack O'Neill
# Developed for a friend that wanted a customizable bot to interact with the Twitch.tv chat interface
#
# Possible expansion is to implement in Rails app in following way:
#  - Require users to authorize bot
#  - Users channel info is stored in simple db
#  - Other db tables store commands and timers that can be added/removed/updated in simple web interface
#  - Web interface has 'start' button, bot is launched on in own spawned process and joins the user's channel
#     - Running in own proc, and db access happens before, so should be no thread safety problems
#     - Should be able to use callbacks with websockets/actioncable to update web interface with feedback on bot
#  - Create a simple process registry, storing {channel_name => PID}
#     - Check if entry exists to see if bot currently running
#     - When user wants bot to leave/stops broadcasting, the process should die and registry entry removed

# UPDATE DECEMBER 2016, THIS WOULD WORK WELL AS AN EXLIR/PHOENIX APP ^

require 'socket'
require 'concurrent'
require 'set'
require 'net/http'
require 'json'
require 'uri'

class Bot
  attr_reader :channel
  attr_reader :mods

  def initialize(channel, commands, timers)
    @commands = commands
    @timers = timers
    
    @channel = channel
    @socket = TCPSocket.open("irc.twitch.tv", 6667)
    @mods = Set.new ['nestabot']
    
    #FEEL FREE TO SUBSTITUTE WITH YOUR OWN OUATH INFO AND BOT NAME, NESTABOT IS SIMPLY A TESTING ACCOUNT
    send "PASS oauth:0ky3dqiusjv72zgfdr0o6638gm7824"
    send "NICK nestabot"
    send "CAP REQ :twitch.tv/membership :twitch.tv/commands" 
    send "JOIN ##{@channel}"

    message_channel "I have arrived"
  end

  #POPULATES THE MODS LIST, WHICH ARE USERS THAT ARE TO BE HANDLED DIFFERENTLY BY THE BOT
  def getMods()
    uri = URI("http://tmi.twitch.tv/group/user/#{@channel}/chatters")
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
    m = json['chatters']['moderators'].to_set
    @mods.merge(m)
  end

  #SEND MESSAGE TO CHANNEL
  def message_channel(msg)
    send "PRIVMSG ##{@channel} :#{msg}"
  end

  #MAIN METHOD
  def run
    self.getMods() # Get mods
    self.timed(@timers) # Initialize Timers
    until @socket.eof? do
      msg = @socket.gets

      puts msg

      if msg.match(/^PING :(.*)$/) # Stay alive via Ping/Pong response
        send "PONG #{$~[1]}"
        next
      end

      # Begin message matching
      if msg.match(/PRIVMSG ##{@channel} :(.*)$/) 
        fullmsg = $~[1]
        if fullmsg[0] == "!"
          nick = msg[/\:(.*?)!/,1].strip
          content = fullmsg[1..-2].downcase
          if @commands.key?(content.to_sym)
            message_channel(@commands[content.to_sym])
          end
          next
        end
      end
    end
  end

  #LEAVE CHANNEL AND CLOSE CONNECTION
  def quit
    send "PART ##{@channel}"
    send 'QUIT'
    @socket.close
  end

  # Sends messages to channel at set intervals
  def timed(hash)
    hash.each do |interval, message|
      task = Concurrent::TimerTask.new(execution_interval: interval, timeout_interval: 60) do
        message_channel("#{message}") 
      end    
      task.execute
    end
  end

  private

  #HELPER METHOD
  def send(msg)
    puts msg
    @socket.puts msg
  end

end


