defmodule ElixirRabbitmqTest do
  use ExUnit.Case
  doctest ElixirRabbitmq

  test "greets the world" do
    assert ElixirRabbitmq.hello() == :world
  end
end
