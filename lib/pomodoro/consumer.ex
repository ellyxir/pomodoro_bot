defmodule Pomodoro.Consumer do
  use Nostrum.Consumer

  require Logger

  @server_id 1_319_711_659_475_865_702
  @command_name "pomo-start"

  def handle_event({:READY, _ready_event, _ws_state}) do
    Logger.debug("got ready event")
    register_guild_commands(@server_id)
  end

  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           user: %Nostrum.Struct.User{id: user_id},
           data: %{name: @command_name} = data
         } = interaction, _ws_state}
      ) do
    [
      %Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: "work",
        value: work_duration
      },
      %Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: "break",
        value: break_duration
      }
    ] = data.options

    Logger.debug(
      "work duration=#{inspect(work_duration)}, break duration=#{inspect(break_duration)}"
    )

    Pomodoro.TimerServerSupervisor.start_timer_server(user_id)
    |> IO.inspect(label: "timerserver including STATE=")

    elapsed_time = Pomodoro.TimerServer.start_timer(user_id, work_duration)

    # acknowledge command
    response =
      %{
        type: Nostrum.Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{
          content: "timer start command received: elapse time=#{elapsed_time}"
          # ephermeral message
          # flags: 64
        }
      }

    Nostrum.Api.create_interaction_response(interaction, response)
  end

  @spec register_guild_commands(Nostrum.Struct.Guild.id()) :: :ok
  def register_guild_commands(guild_id) when is_integer(guild_id) do
    command = %{
      name: "pomo-start",
      description: "start a pomodoro timer",
      options: [
        %{
          type: Nostrum.Constants.ApplicationCommandOptionType.integer(),
          name: "work",
          description: "minutes for work timer",
          required: true
        },
        %{
          type: Nostrum.Constants.ApplicationCommandOptionType.integer(),
          name: "break",
          description: "minutes for break timer",
          required: true
        }
      ]
    }

    {:ok, _ret_map} = Nostrum.Api.create_guild_application_command(guild_id, command)
    :ok
  end
end
