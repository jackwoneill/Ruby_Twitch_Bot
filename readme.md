<snippet>
  <content><
# Ruby Twitch Bot
This is a simple twitch bot written in Ruby. OOTB allows for matched commands as well as timed events.
## Usage
It is currently set up with an account I used during testing, which will never be used again.  Feel free to use the current account/oauth setup. If you wish to change, change the appropriate fields in the /initialize method.

To initialize an instance of the bot, include the code in your project and initialize as such.

```ruby
# Create a Hash object containing the commands you wish to match and the desired response
# The Hash key is the command to match, the value is the desired output
commands = Hash.new(:name => "Jack O'Neill", :age => "21")

# Timers act as a way to routinely post to the chat
# The key is the time interval in minutes, the value is the message to post.
timers = {"10" => "I will be posted every 10 minutes.",  "15" => "And I will be posted every 15 minutes."}

# Initialize a new instance of the bot as such
bot_instance = Bot.new('channel_name', commands, timers)
```
]]></content>
  <tabTrigger>readme</tabTrigger>
</snippet>