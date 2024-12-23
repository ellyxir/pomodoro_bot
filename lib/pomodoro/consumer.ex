defmodule Pomodoro.Consumer do
  use Nostrum.Consumer

  require Logger

  @command_name "pomo-start"

  def handle_event({:READY, _ready_event, _ws_state}) do
    Logger.debug("got ready event")
    register_guild_commands()
  end

  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           user: %Nostrum.Struct.User{id: user_id},
           data: %{name: "pomo-check"} = _data,
           channel_id: channel_id
         } = interaction, _ws_state}
      ) do
    Pomodoro.TimerServerSupervisor.start_timer_server(user_id, channel_id)

    {is_running, elapsed_time} = 
      case Pomodoro.TimerServer.check_timer(user_id) do
        {:ok, is_running, elapsed_time} -> {is_running, elapsed_time}
        other -> 
          Logger.error("got other: #{inspect other}")
          {false, 0}
      end
    timer_status_msg = if is_running, do: "Your timer is running", else: "Your timer is not running"
    embed = 
      %Nostrum.Struct.Embed{}
      |> Nostrum.Struct.Embed.put_title("#{interaction.user.username} Pomodoro Timer")
      |> Nostrum.Struct.Embed.put_description("#{timer_status_msg}\nElapsed time: #{elapsed_time} seconds")
    response =
      %{
        type: Nostrum.Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{
          content: "<@#{user_id}>",
          embed: embed
          # ephermeral message
          # flags: 64
        }
      }

    Nostrum.Api.create_interaction_response(interaction, response)
  end
    
  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           user: %Nostrum.Struct.User{id: user_id},
           data: %{name: @command_name} = data,
           channel_id: channel_id
         } = interaction, _ws_state}
      ) do
    [
      %Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: "work-min",
        value: work_duration
      },
      %Nostrum.Struct.ApplicationCommandInteractionDataOption{
        name: "break-min",
        value: break_duration
      }
    ] = data.options

    Logger.debug(
      "work duration=#{inspect(work_duration)}, break duration=#{inspect(break_duration)}"
    )

    Pomodoro.TimerServerSupervisor.start_timer_server(user_id, channel_id)
    |> IO.inspect(label: "timerserver including STATE=")

    _elapsed_time = Pomodoro.TimerServer.start_timer(user_id, work_duration, break_duration)

    # acknowledge command
    embed = 
      %Nostrum.Struct.Embed{}
      |> Nostrum.Struct.Embed.put_title("#{interaction.user.username} Pomodoro Timer")
      |> Nostrum.Struct.Embed.put_description("Work time: #{work_duration} minutes\nBreak time: #{break_duration} minutes")
      |> Nostrum.Struct.Embed.put_footer("Time to get to work! Be productive!")
    response =
      %{
        type: Nostrum.Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{
          content: "<@#{user_id}>",
          embed: embed
          # ephermeral message
          # flags: 64
        }
      }

    Nostrum.Api.create_interaction_response(interaction, response)
  end

  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           user: %Nostrum.Struct.User{id: user_id},
           data: %{custom_id: "StartWorkTimer"} = _data,
           channel_id: _channel_id
         } = interaction, _ws_state}
      ) do
    embed =
      case Pomodoro.TimerServer.restart_timer(user_id, :work) do
        {:ok, duration} -> 
          %Nostrum.Struct.Embed{}
          |> Nostrum.Struct.Embed.put_title("#{interaction.user.username} Pomodoro Timer")
          |> Nostrum.Struct.Embed.put_description("Starting work timer for #{duration} minutes")
          |> Nostrum.Struct.Embed.put_footer("Time to get to work! Be productive!")

        {:error, reason} -> "Could not restart timer, reason=#{inspect(reason)}"
      end

    # acknowledge command
    response =
      %{
        type: Nostrum.Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{
          content: "<@#{user_id}>",
          embed: embed
          # ephermeral message
          # flags: 64
        }
      }

    Nostrum.Api.create_interaction_response(interaction, response)
  end

  def handle_event(
        {:INTERACTION_CREATE,
         %Nostrum.Struct.Interaction{
           user: %Nostrum.Struct.User{id: user_id},
           data: %{custom_id: "StartBreakTimer"} = _data,
           channel_id: _channel_id
         } = interaction, _ws_state}
      ) do
    embed =
      case Pomodoro.TimerServer.restart_timer(user_id, :work) do
        {:ok, duration} -> 
          %Nostrum.Struct.Embed{}
          |> Nostrum.Struct.Embed.put_title("#{interaction.user.username} Pomodoro Timer")
          |> Nostrum.Struct.Embed.put_description("Starting break timer for #{duration} minutes")
          |> Nostrum.Struct.Embed.put_footer("Time to get to work! Be productive!")
      end
    # acknowledge command
    response =
      %{
        type: Nostrum.Constants.InteractionCallbackType.channel_message_with_source(),
        data: %{
          content: "<@#{user_id}>",
          embed: embed
          # ephermeral message
          # flags: 64
        }
      }

    Nostrum.Api.create_interaction_response(interaction, response)
  end

  # def handle_event(event) do
  #   Logger.error("handle_event: not handling event: #{inspect(event, pretty: true)}")
  # end

  @spec register_guild_commands() :: :ok
  def register_guild_commands() do
    pomo_start_command = %{
      name: "pomo-start",
      description: "start a pomodoro timer",
      options: [
        %{
          type: Nostrum.Constants.ApplicationCommandOptionType.integer(),
          name: "work-min",
          description: "minutes for work timer",
          required: true
        },
        %{
          type: Nostrum.Constants.ApplicationCommandOptionType.integer(),
          name: "break-min",
          description: "minutes for break timer",
          required: true
        }
      ]
    }
    pomo_check_command = %{
      name: "pomo-check",
      description: "Check current status of your Pomodoro Timer",
    }

    {:ok, _ret_map} = Nostrum.Api.create_global_application_command( pomo_start_command)
    {:ok, _ret_map} = Nostrum.Api.create_global_application_command( pomo_check_command)
    :ok
  end
end
