defmodule ElixirRabbitmq.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_rabbitmq,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix release" to compile releases.
  defp releases() do
    [
      elixir_rabbitmq: [
        include_executables_for: [:unix]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :amqp],
      mod: {ElixirRabbitmq.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:amqp, "0.1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
