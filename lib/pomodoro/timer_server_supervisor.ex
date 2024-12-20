defmodule Pomodoro.TimerServerSupervisor do
  use DynamicSupervisor
  require Logger

  @spec start_timer_server(Nostrum.Struct.User.id()) :: DynamicSupervisor.on_start_child()
  def start_timer_server(user_id) do
    Logger.debug("start_timer_server: userid=#{user_id}")

    DynamicSupervisor.start_child(__MODULE__, {Pomodoro.TimerServer, user_id})
  end

  def start_link(init_arg) do
    Logger.error("supervisor start_link")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    Logger.error("supervisor init, init_arg=#{inspect(init_arg)}")
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
