defmodule ElixirRabbitmq.Consumers.Test1 do
    use GenServer, start: {__MODULE__, :start_link, []}
    require Logger
    use AMQP
    alias ElixirRabbitmq.DynamicConsumer
    alias ElixirRabbitmq.Connection, as: ElRabbitmqConnection

    @reconnect_interval 5_000
    @queue "test_1"

    def child_spec(opts) do
        %{
            id: DynamicConsumer.id(opts),
            start: {__MODULE__, :start_link, [opts]},
            type: :worker
        }
    end

    def start_link(opts, params) do
        GenServer.start_link(__MODULE__, opts, name: DynamicConsumer.id(params))
    end
    
    def init(_) do
        Process.flag(:trap_exit, true)
        Process.send_after(self(), :connect, 0)
        {:ok, nil}
    end    

    def handle_info(:connect, state) do
        case ElRabbitmqConnection.get_connection() do
            {:ok, conn} ->
                # Get notifications when the connection goes down
                Process.monitor(conn.pid)
                case Channel.open(conn) do
                    {:ok, chan} ->
                        Basic.qos(chan, prefetch_count: 1)
                        Process.monitor(chan.pid)
                        Queue.declare(chan, @queue, durable: true, routing_key: @queue)
                        {:ok, _consumer_tag} = Basic.consume(chan, @queue)
                        {:noreply, chan}
                    _ ->
                        Logger.error("Faile to open channel!")
                        Process.send_after(self(), :send, @reconnect_interval)
                        {:noreply, state}
                end
    
            {:error, _} ->
                Logger.error("Failed to connect. Reconnecting later...")
                Process.send_after(self(), :connect, @reconnect_interval)
                {:noreply, state}
        end
    end

    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
        {:noreply, chan}
    end

    # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
    def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
        Logger.warn("Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)")
        {:stop, :normal, chan}
    end

    # Confirmation sent by the broker to the consumer process after a Basic.cancel
    def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
        {:noreply, chan}
    end

    # handle timeout error
    def handle_info(:timeout, _state) do
        {:stop, :error, nil}
    end
    
    # handle ssl closed error
    def handle_info({:ssl_closed, _msg}, state) do
        {:noreply, state}
    end

    # Handle all messages from queue
    def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
        # also can be used with spawn
        # spawn fn -> consume(chan, tag, redelivered, payload) end
        consume(chan, tag, redelivered, payload)
        {:noreply, chan}
    end    

    def consume(chan, tag, redelivered, payload) do
        Logger.info("||||||||||||||||||||||||||||||||||||||||||", ansi_color: :blue)
        Logger.info(inspect(self()))
        Logger.info(inspect(payload))
        Logger.info(inspect(tag))
        Logger.info(inspect(redelivered))
        Logger.info("||||||||||||||||||||||||||||||||||||||||||", ansi_color: :blue)
        # Retry consuming a message once in case of exception
        # Basic.reject(chan, tag, requeue: not redelivered)
        # Reject message 
        # Basic.reject(chan, tag, requeue: false)
        # Accept message 
        Basic.ack(chan, tag)
    end
end