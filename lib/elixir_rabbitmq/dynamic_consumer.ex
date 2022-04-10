defmodule ElixirRabbitmq.DynamicConsumer do
    use DynamicSupervisor
    require Logger

    def start_link(init_arg) do
        DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    @impl true
    def init(init_arg) do
        {:ok, _} = Task.start_link(fn ->
            spawn_consumers()
        end)
        DynamicSupervisor.init(
            strategy: :one_for_one,
            extra_arguments: [init_arg]
        )
    end

    def id(%{id: id, name: name}) do
        String.to_atom("consumer_#{name}_#{id}")
    end

    def stop_child(pid) do
        Logger.info("#{__MODULE__} | Process #{inspect(pid)} successful stoped", ansi_color: :green)
        DynamicSupervisor.terminate_child(__MODULE__, pid)
    end

    def new_child(params) do
        module = params.consumer
        spec = module.child_spec(params)

        case DynamicSupervisor.start_child(__MODULE__, spec) do
            {:ok, pid} -> {:ok, pid}
            {:error, {:already_started, pid}} -> {:already_started, pid}
            error -> raise "#{__MODULE__} new_child/1 ERROR -> #{inspect error}"
        end
        DynamicSupervisor.count_children(__MODULE__) |> IO.inspect()
    end

    def spawn_consumers do
        elixir_rabbitmq_queues = Application.get_env(:elixir_rabbitmq, :queue_conf)[:elixir_rabbitmq].queues
        queues = elixir_rabbitmq_queues

        Enum.each(queues, fn queue_conf -> 
            Enum.each(1..queue_conf.consumers_count, fn consumer_count ->
                spawn(fn -> new_child(Map.put(queue_conf, :id, consumer_count)) end)
            end)
        end)
    end
end