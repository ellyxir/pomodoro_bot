defmodule PomodoroTest do
  use ExUnit.Case
  doctest Pomodoro

  test "greets the world" do
    assert Pomodoro.hello() == :world
  end
end
