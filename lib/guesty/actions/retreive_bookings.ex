defmodule Guesty.Actions.RetrieveBookings do
  @moduledoc false

  require Logger

  @type args() :: map()
  @type response() :: {:ok, term(), term()} | {:error, term(), term()}

  @doc false
  def perform do
    case get_booking_revisions() do
      {:ok, %{"data" => data}} -> push_bookings(data)
      error -> log_error(error)
    end
  end

  defp get_booking_revisions do
    %{headers: [user_api_key: user_api_key()], method: :get, endpoint: "booking_revisions/feed"}
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp push_bookings(data) do
    data
    |> Stream.map(&push_booking/1)
    |> Stream.map(&ack_booking/1)
    |> Stream.run()
  end

  defp push_booking(%{"attributes" => booking}) do
    case Guesty.push_bookings(%{booking: booking}) do
      {:ok, %{success: true}} ->
        Logger.info(ctx: __MODULE__, id: booking["id"], pushed: true)
        {:ok, %{id: booking["id"], success: true}}

      error ->
        Logger.error(ctx: __MODULE__, error: error, id: booking["id"], pushed: false)
        error
    end
  end

  defp ack_booking({:ok, args}) do
    with {:ok, %{success: true}} <- Guesty.ack_booking(args) do
      Logger.info(ctx: __MODULE__, id: args.id, acked: true)
    end
  end

  defp ack_booking(response) do
    Logger.error(ctx: __MODULE__, response: response, acked: false)
  end

  defp log_error(error) do
    Logger.error(ctx: __MODULE__, error: error)
  end

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp user_api_key, do: Application.fetch_env!(:guesty, :user_api_key)
end
