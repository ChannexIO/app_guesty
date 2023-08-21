defmodule Guesty.Application do
  @moduledoc false

  use Application

  alias Guesty.{Cache, BookingFetcher, PromEx, Receiver, Router, RPCReceiver, TasksPerformer}

  @env Application.compile_env!(:guesty, :env)

  @impl true
  def start(_type, _args) do
    children = [
      {Cache, is_active: @env != :test},
      {Receiver, receiver_opts()},
      {Bandit, webserver_opts()},
      PromEx,
      TasksPerformer,
      {RPCReceiver, rpc_receiver_opts()},
      BookingFetcher
    ]

    opts = [strategy: :one_for_one, name: Guesty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp receiver_opts do
    [
      app_name: "guesty",
      queue: "applications.guesty",
      exchange: "applications"
    ]
  end

  defp rpc_receiver_opts do
    [
      service_name: "Guesty",
      queue: "guesty.rpcs",
      connection: connection(),
      module: Guesty
    ]
  end

  defp webserver_opts do
    [scheme: :http, plug: Router, port: 8080]
  end

  defp connection, do: Application.fetch_env!(:message_queue, :connection)
end
