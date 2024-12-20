defmodule Pomodoro.Registry do
  require Logger

  def start_link() do
    Logger.debug("registry starting")
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end

  def via_tuple(key) do
    {:via, Registry, {Pomodoro.Registry, key}}
  end
end
