import Config

if config_env() == :prod do
  config :guesty,
    user_api_key: System.get_env("GUESTY_USER_API_KEY"),
    api_url: System.get_env("GUESTY_API_URL"),
    base_url: System.get_env("GUESTY_BASE_URL"),
    booking_api_url: System.get_env("GUESTY_BOOKING_API_URL"),
    pci_key: System.get_env("PCI_PROXY_KEY"),
    credentials: %{
      api_key: System.get_env("GUESTY_API_KEY")
    }

  config :guesty, Guesty.PromEx,
    grafana: [
      host: System.get_env("GRAFANA_HOST", "http://grafana-service:3000"),
      username: System.get_env("GRAFANA_USERNAME"),
      password: System.get_env("GRAFANA_PASSWORD"),
      upload_dashboards_on_start: true
    ]

  config :appsignal, :config,
    name: System.get_env("APPSIGNAL_APP_NAME"),
    push_api_key: System.get_env("APPSIGNAL_API_KEY")

  case System.get_env("PROXY_ADDRESSES") do
    nil ->
      nil

    proxies ->
      config :http_client,
             :proxy,
             proxies
             |> String.split(";")
             |> Enum.map(fn url ->
               [address, port] = String.split(url, ":")
               %{scheme: :http, address: address, port: port, opts: []}
             end)
  end
end
