defmodule ElixirRabbitmq.Publisher do
  use GenServer
  require Logger
  use AMQP

  @moduledoc """
    Module for publish messages into queues.
  """

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, []}
  end

  def publish({_conn_type, _queue, _message} = opts) do
    GenServer.cast(__MODULE__, opts)
  end

  def handle_cast({conn_type, queue, message}, state) do
    connection_module =
      Application.get_env(:elixir_rabbitmq, :queue_conf)[conn_type].connection_module

    case connection_module.get_channel do
      {:ok, chan} ->
        publish_data(chan, %{queue: queue, message: message})
        {:noreply, state}

      {:error, :not_connected} ->
        {:noreply, state}
    end
  end

  defp publish_data(chan, %{queue: queue, message: message}) do
    if Process.alive?(chan.pid) do
      case Basic.publish(chan, "", queue, "#{message}") do
        :ok ->
          Logger.info("Message \"#{message}\" succeful published", ansi_color: :blue)
          :ok

        _ ->
          Logger.error("Failure message publish #{message}")
          :error
      end
    else
      Logger.error("Channel #{inspect(chan)} is not alive")
      :error
    end
  end
end
