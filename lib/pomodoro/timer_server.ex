defmodule Pomodoro.TimerServer do
  use GenServer
  require Logger

  @moduledoc """
  GenServer that runs for each discord user, keeps track
  of their timer

  our state is 
  user_id: discord id
  start_time_sec: the time timer started via System.monotonic_time() in seconds, when the timer is "done" or not active, this value is nil
  work_duration_min: how long the work timer lasts
  break_duration_min: how long the break timer lasts
  """

  defstruct [
    :user_id,
    :channel_id,
    start_time_sec: nil,
    work_duration_min: nil,
    break_duration_min: nil
  ]

  def start_timer(user_id, duration_min) do
    GenServer.call(via_tuple(user_id), {:start_timer, duration_min})
  end

  def restart_timer(user_id) do
    GenServer.call(via_tuple(user_id), {:restart_timer})
  end

  def start_link({user_id, channel_id} = init_arg)
      when is_integer(user_id) and is_integer(channel_id) do
    Logger.debug("timerserver start_link: init_arg=#{inspect(init_arg)}")
    GenServer.start_link(__MODULE__, init_arg, name: via_tuple(user_id))
  end

  @impl true
  def init({user_id, channel_id}) when is_integer(user_id) and is_integer(channel_id) do
    state = %__MODULE__{user_id: user_id, channel_id: channel_id}
    Logger.error("timerserver init=#{inspect(user_id)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:start_timer, duration_min}, _from, state)
      when state.start_time_sec == nil do
    Logger.debug(
      "handle_call: start_timer, start state=#{inspect(state)} duration=#{duration_min}"
    )

    # send a message to ourselves after timer is done
    # Process.send_after(self(), {:timers_up}, duration_min * 60 * 1000)
    Process.send_after(self(), {:timers_up}, 3000)

    current_time_sec = System.monotonic_time(:second)
    new_state = %{state | work_duration_min: duration_min, start_time_sec: current_time_sec}

    {:reply, 0, new_state}
    |> IO.inspect(label: "reply from start_timer")
  end

  # called when the timer is already running
  def handle_call({:start_timer, _duration_min}, _from, %__MODULE__{} = state) do
    current_time_sec = System.monotonic_time(:second)
    elapsed_time = current_time_sec - state.start_time_sec
    {:reply, elapsed_time, state}
  end

  def handle_call({:restart_timer}, _from, %__MODULE__{} = state)
      when state.start_time_sec == nil do
    Logger.debug("restarting timer for user: #{state.user_id}")
    Process.send_after(self(), {:timers_up}, 3000)
    new_state = %{state | start_time_sec: System.monotonic_time(:second)}
    {:reply, {:ok}, new_state}
  end

  def handle_call({:restart_timer}, _from, %__MODULE__{} = state) do
    Logger.error("tried to restart timer but its already running")
    {:reply, {:error, "timer already running"}, state}
  end

  @start_work_button_name "StartWorkTimer"
  @start_break_button_name "StartBreakTimer"
  @impl true
  def handle_info({:timers_up}, %__MODULE__{} = state) do
    Logger.debug("timer_server: timer is UP! state=#{inspect(state, pretty: true)}")

    work_button =
      Nostrum.Struct.Component.Button.interaction_button(
        "Start Work Timer",
        @start_work_button_name
      )

    break_button =
      Nostrum.Struct.Component.Button.interaction_button(
        "Start Break Timer",
        @start_break_button_name
      )

    content_options = %{
      content: "here is my content",
      components: [
        Nostrum.Struct.Component.ActionRow.action_row()
        |> Nostrum.Struct.Component.ActionRow.append(work_button)
        |> Nostrum.Struct.Component.ActionRow.append(break_button)
      ]
    }

    Nostrum.Api.create_message(state.channel_id, content_options)
    new_state = %{state | start_time_sec: nil}
    {:noreply, new_state}
  end

  def get_start_work_button_name, do: @start_work_button_name
  def get_start_break_button_name, do: @start_break_button_name

  def via_tuple(user_id) do
    Pomodoro.Registry.via_tuple({__MODULE__, user_id})
  end
end
