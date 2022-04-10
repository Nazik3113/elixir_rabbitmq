import Config

config :elixir_rabbitmq, :queue_conf,
  elixir_rabbitmq: %{
    user: System.get_env("USER"),
    password: System.get_env("PASSWORD"),
    host: System.get_env("HOST"),
    port: System.get_env("PORT"),
    connection_module: ElixirRabbitmq.Connection,
    queues: [
      %{
        name: "test_1",
        delay: "test_1_delay",
        delay_time: 300_000,
        exchange: "test_1",
        consumers_count: 5,
        consumer: ElixirRabbitmq.Consumers.Test1
      },
      %{
        name: "test_2",
        delay: "test_2_delay",
        delay_time: 300_000,
        exchange: "test_2",
        consumers_count: 5,
        consumer: ElixirRabbitmq.Consumers.Test2
      }
    ]
  }
