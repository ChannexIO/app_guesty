defmodule Guesty.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :guesty,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Guesty.Application, []}
    ]
  end

  defp releases do
    [
      guesty: [
        applications: [
          guesty: :permanent,
          runtime_tools: :permanent
        ],
        version: @version
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:http_client, github: "ChannexIO/http_client", branch: "add-steps"},
      {:message_queue, github: "ChannexIO/message_queue", tag: "v0.6.4"},
      {:broadway_rabbitmq, "~> 0.7"},
      {:appsignal, "~> 2.5"},
      {:bandit, ">= 0.6.9"},
      {:jsonrs, "~> 0.2.1"},
      {:prom_ex, "~> 1.7"},
      {:ex_json_schema, "~> 0.9.2"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:finch, "~> 0.14", override: true},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
