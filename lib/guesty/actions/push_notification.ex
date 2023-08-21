defmodule Guesty.Actions.PushNotification do
  @moduledoc false

  require Logger

  @type args() :: binary()
  @type response() :: {:ok, term()} | {:error, term()}

  @statuses %{enable: "y", disable: "n"}

  @doc false
  def perform(hotel_code, status) do
    with {:ok, response} <- send_request(hotel_code, status) do
      {:ok, response}
    else
      error -> log_error(error)
    end
  end

  defp send_request(hotel_code, status) do
    [
      url: api_url(),
      headers: ["Content-Type": "application/json"],
      payload: {:json, compose_payload(hotel_code, status)}
    ]
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, %{"status" => _} = response, _meta}), do: {:ok, response}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp log_error(error) do
    Logger.error(ctx: __MODULE__, error: error)
    error
  end

  defp compose_payload(hotel_code, status) do
    %{
      propertyid: hotel_code,
      apikey: api_key(),
      action: :push_api_status,
      status: @statuses[status]
    }
  end

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp api_url, do: Application.fetch_env!(:guesty, :api_url)
  defp api_key, do: Application.fetch_env!(:guesty, :credentials)[:api_key]
end
