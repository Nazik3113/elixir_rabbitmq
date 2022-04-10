defmodule ElixirRabbitmq.Connection do
    use GenServer
    use AMQP
    require Logger

    @reconnect_interval 5_000

    def start_link(_) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    @impl true
    def init(_) do
        Process.send_after(self(), :init_connection, 0)
        {:ok, nil}
    end

    def get_connection do
        case GenServer.call(__MODULE__, :get_connection) do
            %AMQP.Connection{} = conn -> {:ok, conn}
            _ -> {:error, :not_connected}
        end
    end

    def get_channel do
        case GenServer.call(__MODULE__, :get_channel) do
            %AMQP.Channel{} = chan -> {:ok, chan}
            _ -> {:error, :not_connected}
        end
    end

    def reconnect do
        case GenServer.call(__MODULE__, :reconnect) do
            %AMQP.Channel{} = _chan -> {:ok, :success}
            _ -> {:error, :not_connected}
        end
    end

    @impl true
    def handle_call(:get_connection, _from, chan) do
        case chan do
            %AMQP.Channel{} = chan ->
                {:reply, chan.conn, chan}
            _ -> 
                {:reply, nil, chan}
        end
    end

    @impl true
    def handle_call(:get_channel, _from, chan) do
        case chan do
            %AMQP.Channel{} = chan ->
                {:reply, chan, chan}
            _ -> 
                {:reply, nil, chan}
        end
    end

    @impl true
    def handle_call(:reconnect, _from, chan) do
        case chan do
            %AMQP.Channel{} = chan ->
                Channel.close(chan)
                Connection.close(chan.conn)
                {:reply, chan, chan}
            _ -> 
                {:reply, nil, chan}
        end
    end

    @impl true
    def handle_info(:init_connection, _from) do
        config = Application.get_env(:elixir_rabbitmq, :queue_conf)[:elixir_rabbitmq]

        case Connection.open("amqp://#{config.user}:#{config.password}@#{config.host}:#{config.port}") do
            {:ok, conn} -> 
                # Get notifications when the connection goes down
                Process.monitor(conn.pid)
                {:noreply, define_queues(conn)}
            {:error, _} ->
                # Reconnection loop
                Logger.error("Failed to connect. Reconnecting...")
                Process.send_after(self(), :init_connection, @reconnect_interval)
                {:noreply, nil}
        end
    end

    @impl true
    def handle_info({:DOWN, _, :process, _pid, reason}, _) do
        Logger.error("AMPQ connection closed with reason: #{reason}.")
        {:stop, {:connection_lost, reason}, nil}
    end

    def define_queues(conn) do
        case Channel.open(conn) do
            {:ok, chan} ->
                queues = Application.get_env(:elixir_rabbitmq, :queue_conf)[:elixir_rabbitmq].queues

                Enum.each(queues, fn queue -> 
                    if queue[:name] do
                        Queue.declare(chan, queue[:name], durable: true, routing_key: queue[:name])
                    end
                    if queue[:prefetch_count] do
                        Basic.qos(chan, prefetch_count: queue[:prefetch_count])
                    end
                    if queue[:exchange] do
                        Exchange.declare(chan, queue[:exchange], :topic, durable: true)
                    end
                    if queue[:delay] do
                        Queue.declare(
                            chan, 
                            queue[:delay], 
                            durable: true,
                            arguments: [
                                {"x-dead-letter-exchange", :longstr, queue[:exchange]},
                                {"x-dead-letter-routing-key", :longstr, queue[:name] },
                                {"x-message-ttl", queue[:delay_time]}
                            ]
                        )
                        Queue.bind(chan, queue[:name], queue[:exchange],[routing_key: queue[:name]])
                    end
                end)
                chan
            _ ->
                Logger.error("Failed to open channel! Reopening...")
                :timer.sleep(1000)
                define_queues(conn)    
        end
    end
end