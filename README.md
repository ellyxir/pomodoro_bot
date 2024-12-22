# Pomodoro

**TODO: Add description**

## TODO
* keep track of break time
* handle break button press

## Add Bot to your Server
url = https://discord.com/oauth2/authorize?client_id=1319706549479931995&permissions=8&integration_type=0&scope=bot

## Requirements
Users will use /pomo-start work:10min break:5min (change the time period) to start their timer. 

When the timer goes off, the creator of the timer will be tagged in a message with 2 button, one for break, one for work. This will start the timer based on what they set for work and break in the initial message.

There can be 1 pomo timer at a time per user and users can start a new timer only after their original timer has gone off. 

my terribles notes:
each person can have at most one timer globally across all channels,
we mention the person on all subsequent messages, such as "time for a break @user "
when a timer work or break duration is done, bot sends new message, tags user, and has a "work" and "break" buttons
only the timer creator can click those buttons (maybe ephemeral message saying this isnt your timer if its not the owner, type /pomo-start to make your own) 
the buttons carry over the state, which is means the buttons encode work duration and break duration 
delete message the bot message with the buttons and send new message when they click on a button. Your [work/break] timer for X minutes has started. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pomodoro` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pomodoro, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pomodoro>.

