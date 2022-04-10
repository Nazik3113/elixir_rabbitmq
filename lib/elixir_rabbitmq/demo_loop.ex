defmodule ElixirRabbitmq.DemoLoop do
  use GenServer
  alias ElixirRabbitmq.Publisher
    
  @moduledoc """
    Demo loop messages into queue.
  """

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :start_loop, 1000)
    {:ok, []}
  end

  def handle_info(:start_loop, _from) do
    Publisher.publish({:elixir_rabbitmq, "test_1", "hello from test_1 queue"})
    Process.sleep(500)
    Publisher.publish({:elixir_rabbitmq, "test_2", "hello from test_2 queue"})
    Process.send_after(self(), :start_loop, 1000)
    {:noreply, nil}
  end
end