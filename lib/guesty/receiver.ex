defmodule Guesty.Receiver do
  @moduledoc false

  use MessageQueue.Consumer

  require Logger

  alias Guesty.Cache

  @opts_schema [
    name: [
      doc: "Used for name registration",
      type: :atom,
      default: __MODULE__
    ],
    exchange: [
      doc: "Exchange for applications.",
      type: :string,
      required: true
    ],
    queue: [
      doc: "Queue we're going to consume from and bind it to the exchange.",
      type: :string,
      required: true
    ],
    app_name: [
      doc: "Application name.",
      type: :string,
      required: true
    ]
  ]

  defguardp cache_settings(term)
            when is_map(term) and is_map_key(term, "property_id") and is_map_key(term, "settings")

  @doc """
  Starts Receiver.

  ### Using options
  #{NimbleOptions.docs(@opts_schema)}
  """
  def start_link(init_arg) do
    opts = NimbleOptions.validate!(init_arg, @opts_schema)

    GenServer.start_link(
      __MODULE__,
      %{
        queue: opts[:queue],
        prefetch_count: 1,
        bindings: [{opts[:exchange], [arguments: binding_arguments(opts)]}],
        after_connect: &after_connect(&1, opts)
      },
      name: opts[:name],
      hibernate_after: 15_000
    )
  end

  @doc false
  def handle_message(payload, meta, state) do
    with {:ok, payload} <- decode_payload(payload),
         :ok <- process_payload(payload) do
      :ok = ack(state, meta)
    else
      {:error, :invalid_payload} -> discard(state, meta)
      _ -> requeue(state, meta)
    end
  rescue
    error ->
      log_error(error, meta, __STACKTRACE__)
      discard(state, meta)
  end

  defp after_connect(channel, opts) do
    AMQP.Exchange.declare(channel, opts[:exchange], :headers, durable: true)
  end

  defp binding_arguments(opts) do
    [{opts[:app_name], true}, {"x-match", "any"}]
  end

  defp decode_payload(data) do
    case MessageQueue.decode_data(data) do
      {:ok, payload} -> {:ok, payload}
      _ -> {:error, :invalid_payload}
    end
  end

  defp process_payload(payload) when cache_settings(payload) do
    payload["settings"]
    |> Map.put("property_id", payload["property_id"])
    |> Cache.update()
  end

  defp discard(state, meta) do
    :ok = reject(state, meta, requeue: false)
  end

  defp requeue(state, meta) do
    :ok = reject(state, meta, requeue: true)
  end

  defp log_error(error, meta, stacktrace) do
    Logger.error(error: error, meta: meta, stacktrace: stacktrace)
  end
end
