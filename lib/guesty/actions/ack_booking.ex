defmodule Guesty.Actions.AckBooking do
  @moduledoc false

  require Logger

  @type args() :: map()
  @type response() :: {:ok, %{success: boolean()}}

  @doc false
  def perform(%{success: true, id: id}) do
    with {:ok, response} <- send_request(id),
         {:ok, response} <- format_response(response) do
      {:ok, response}
    else
      error -> log_error(error, id)
    end
  end

  def perform(args), do: log_error(args, nil)

  defp send_request(id) do
    %{headers: [user_api_key: user_api_key()], endpoint: "booking_revisions/#{id}/ack"}
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp format_response(%{"meta" => %{"message" => "Success"}}), do: {:ok, %{success: true}}
  defp format_response(response), do: {:error, response}

  defp log_error(error, id) do
    Logger.error(ctx: __MODULE__, error: error, id: id, acked: false)
    {:ok, %{success: false}}
  end

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp user_api_key, do: Application.fetch_env!(:guesty, :user_api_key)
end
