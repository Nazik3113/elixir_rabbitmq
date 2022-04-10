defmodule ElixirRabbitmq.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ElixirRabbitmq.Worker.start_link(arg)
      # {ElixirRabbitmq.Worker, arg}
      ElixirRabbitmq.Connection,
      ElixirRabbitmq.Publisher,
      ElixirRabbitmq.DynamicConsumer
    ]

    opts = [strategy: :one_for_one, name: ElixirRabbitmq.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
