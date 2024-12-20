defmodule Pomodoro.TimerServer do
  use GenServer
  require Logger

  defstruct [:user_id, start_time_sec: nil, work_duration_min: nil, break_duration_min: nil]

  @moduledoc """
  GenServer that runs for each discord user, keeps track
  of their timer
  """
  def start_timer(user_id, duration_min) do
    GenServer.call(via_tuple(user_id), {:start_timer, duration_min})
  end

  def start_link(user_id) when is_integer(user_id) do
    Logger.error("timerserver start_link: init_arg=#{inspect(user_id)}")
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end

  @impl true
  def init(user_id) when is_integer(user_id) do
    state = %__MODULE__{user_id: user_id}
    Logger.error("timerserver init=#{inspect(user_id)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:start_timer, duration_min}, _from, state)
      when state.start_time_sec == nil do
    Logger.debug(
      "handle_call: start_timer, start state=#{inspect(state)} duration=#{duration_min}"
    )

    current_time_sec = System.monotonic_time(:second)
    new_state = %{state | work_duration_min: duration_min, start_time_sec: current_time_sec}

    {:reply, 0, new_state}
    |> IO.inspect(label: "reply from start_timer")
  end

  def handle_call({:start_timer, _duration_min}, _from, %__MODULE__{} = state) do
    current_time_sec = System.monotonic_time(:second)
    elapsed_time = current_time_sec - state.start_time_sec
    {:reply, elapsed_time, state}
  end

  def via_tuple(user_id) do
    Pomodoro.Registry.via_tuple({__MODULE__, user_id})
  end
end
