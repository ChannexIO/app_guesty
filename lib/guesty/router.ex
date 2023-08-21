defmodule Guesty.Router do
  @moduledoc false

  use Plug.Router

  require Logger

  alias Guesty.DTO.Errors

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jsonrs
  )

  plug(PromEx.Plug, prom_ex_module: Guesty.PromEx)

  plug(Plug.Logger)
  plug(Plug.RequestId)
  plug(:match)
  plug(:dispatch)

  post "/ping" do
    send_resp(conn, 200, conn.assigns.raw_body)
  end

  post "/api/InventorySync" do
    Logger.info(inspect(conn.params))

    case Guesty.sync(conn.params) do
      {:ok, response} -> send_success_response(conn, response)
      {:error, error} -> send_error_response(conn, error)
      {:error, error, meta} -> send_error_response(conn, error, meta)
    end
  end

  post "/api/RateSync" do
    Logger.info(inspect(conn.params))

    case Guesty.sync(conn.params) do
      {:ok, response} -> send_success_response(conn, response)
      {:error, error} -> send_error_response(conn, error)
      {:error, error, meta} -> send_error_response(conn, error, meta)
    end
  end

  post "/reservations" do
    with {:ok, params} <- probe_request(conn.params),
         {:ok, response} <- Guesty.push_bookings(params),
         {:ok, response} <- Guesty.ack_booking(response) do
      send_success_response(conn, response)
    else
      :test_event -> send_success_response(conn, %{success: true})
      {:error, response} -> send_error_response(conn, response)
    end
  end

  get "/" do
    send_resp(conn, 200, "200")
  end

  match _ do
    send_resp(conn, 404, "404")
  end

  defp probe_request(%{"event" => "test"}), do: :test_event
  defp probe_request(params), do: {:ok, params}

  defp send_success_response(conn, response) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Jsonrs.encode!(response))
  end

  defp send_error_response(conn, error, meta \\ %{}) do
    error = Errors.transform(error, meta)

    Logger.error(%{ctx: __MODULE__, error: error, headers: conn.req_headers, params: conn.params})

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(error.status, Jsonrs.encode!(error.payload))
  end
end
