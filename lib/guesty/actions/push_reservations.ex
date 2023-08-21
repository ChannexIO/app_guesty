defmodule Guesty.Actions.PushReservations do
  @moduledoc false

  @type args() :: map()
  @type response() :: {:ok | :error, %{success: boolean()} | atom(), term()}

  @doc false
  def perform(nil), do: {:error, :no_booking, %{}}

  @doc false
  def perform(payload) do
    [
      pci: payload[:token],
      url: api_url(),
      headers: ["Content-Type": "application/json"],
      payload: {:json, prepare_payload(payload)},
      opts: []
    ]
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_payload(payload) do
    %{
      propertyid: payload[:property_id],
      apikey: api_key(),
      action: :reservation_info,
      reservations: %{
        reservation: List.wrap(payload[:reservation])
      }
    }
  end

  defp prepare_response({:ok, [%{"status" => "success"} | _], meta}) do
    {:ok, %{success: true}, meta}
  end

  defp prepare_response({_, response, meta}) do
    {:error, response, meta}
  end

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp api_key, do: Application.fetch_env!(:guesty, :credentials)[:api_key]
  defp api_url, do: Application.fetch_env!(:guesty, :booking_api_url)
end
