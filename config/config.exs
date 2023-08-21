import Config

config :guesty,
  requester: Guesty.Request,
  broadway_producer_module: BroadwayRabbitMQ.Producer,
  user_api_key: System.get_env("GUESTY_USER_API_KEY"),
  base_url: System.get_env("GUESTY_BASE_URL"),
  api_url: System.get_env("GUESTY_API_URL"),
  booking_api_url: System.get_env("GUESTY_BOOKING_API_URL"),
  pci_key: System.get_env("PCI_PROXY_KEY"),
  credentials: %{
    api_key: System.get_env("GUESTY_API_KEY", "test_app_key")
  },
  env: config_env()

config :guesty, Guesty.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: [
    port: 4021,
    path: "/metrics",
    protocol: :http,
    pool_size: 5,
    cowboy_opts: [],
    auth_strategy: :none
  ]

config :message_queue,
  adapter: :rabbitmq,
  connection: [host: "localhost", username: "guest", password: "guest"]

config :logger, truncate: :infinity
config :logger, :console, truncate: :infinity

import_config "#{config_env()}.exs"
