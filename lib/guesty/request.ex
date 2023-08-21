defmodule Guesty.Request do
  @moduledoc false

  defstruct endpoint: nil,
            url: nil,
            method: :post,
            payload: "",
            pci: nil,
            headers: [],
            opts: []

  use HTTPClient, adapter: :finch

  require Logger

  alias Guesty.DTO.Meta

  @type t() :: %__MODULE__{}
  @type response() :: {:ok | :error | :network_error, term(), Meta.t()}

  @callback new(data :: map()) :: t()
  @callback perform(request :: t()) :: response()

  @request_timeout :timer.seconds(60)

  @doc "Builds `Guesty.Request` struct with provided data."
  @spec new(map()) :: t()
  def new(data) do
    struct(%__MODULE__{}, data)
  end

  @spec perform(%{:headers => any, :opts => keyword, :payload => any, optional(any) => any}) ::
          {:error, binary, any} | {:ok, binary, any}
  @doc "Sends HTTP requests to endpoints."
  def perform(request) do
    url = set_url(request)
    method = set_method(request)
    payload = request.payload
    headers = request.headers
    opts = set_opts(request)
    meta = Meta.new(%{request: payload, started_at: NaiveDateTime.utc_now()})

    case request(method, url, payload, headers, opts) do
      {:ok, %{status: status} = response} when status in 200..204 ->
        {:ok, response.body, finalize_meta(meta, response)}

      {:ok, response} ->
        {:error, response.body, finalize_meta(meta, response)}

      {:error, exception} when is_exception(exception) ->
        message = Exception.message(exception)
        response = %{code: "network_error", message: message}
        {:error, response, finalize_meta(meta, response, message)}
    end
  end

  defp set_method(%{pci: pci}) when not is_nil(pci), do: :post
  defp set_method(%{method: method}), do: method

  defp set_url(%{pci: pci, method: method} = request) when not is_nil(pci) do
    url = set_url(%{request | pci: nil})

    Enum.join([
      "https://pci.channex.io/api/v1/cards/",
      pci,
      "/send?api_key=#{pci_key()}&method=#{method}&url=#{url}"
    ])
  end

  defp set_url(%{endpoint: endpoint, url: nil}), do: Enum.join([base_url(), endpoint], "/")
  defp set_url(%{endpoint: nil, url: url}), do: url
  defp set_url(%{endpoint: endpoint, url: url}), do: Enum.join([url, endpoint], "/")

  defp set_opts(%{opts: opts}) do
    opts
    |> Keyword.put(:raw, false)
    |> Keyword.put(:recv_timeout, @request_timeout)
    |> Keyword.put(:timeout, @request_timeout)
  end

  defp finalize_meta(meta, response, errors \\ []) do
    Meta.update(meta, %{
      status_code: Map.get(response, :status),
      response: Map.get(response, :body, response),
      finished_at: NaiveDateTime.utc_now(),
      errors: meta.errors ++ List.wrap(errors),
      headers: Map.get(response, :headers)
    })
  end

  defp base_url, do: Application.fetch_env!(:guesty, :base_url)
  defp pci_key, do: Application.fetch_env!(:guesty, :pci_key)
end
