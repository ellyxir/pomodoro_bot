defmodule Pomodoro.TimerServer do
  use GenServer
  require Logger

  def start_timer(user_id, duration_min) do
    GenServer.call(via_tuple(user_id), {:start_timer, duration_min})
  end

  def start_link(user_id) when is_integer(user_id) do
    Logger.error("timerserver start_link: init_arg=#{inspect(user_id)}")
    GenServer.start_link(__MODULE__, user_id, name: via_tuple(user_id))
  end

  @impl true
  def init(user_id) when is_integer(user_id) do
    state = %{}
    Logger.error("timerserver init=#{inspect(user_id)}")
    {:ok, state}
  end

  @impl true
  def handle_call({:start_timer, duration_min}, _from, state) do
    Logger.debug("handle_call: start_timer, duration=#{duration_min}")
    {:reply, {:from_timerserver}, state}
  end

  def via_tuple(user_id) do
    Pomodoro.Registry.via_tuple({__MODULE__, user_id})
  end
end
