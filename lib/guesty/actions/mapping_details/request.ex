defmodule Guesty.Actions.MappingDetails.Request do
  @moduledoc false

  alias Apaleo.Actions.Helpers

  @doc false
  def execute({:ok, args}) do
    with {:ok, listing} <- send_request(args, :listing),
        {:ok, rate_plans} <- send_request(args, :rate_plans) do
      {:ok, %{listing: listing, rate_plans: rate_plans}}
    end
  end

  def execute(error), do: error

  defp send_request(args, type) do
    [
      method: :get,
      url: api_url(),
      endpoint: get_endpoint(args, type),
      headers: ["Content-Type": "application/json"],
    ]
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp get_endpoint(args, :listing), do: "/content/Listings/#{args[:listing_id]}"
  defp get_endpoint(args, :rate_plans), do: "content/Listings/#{args[:listing_id]}/rate-plans"

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp api_url, do: Application.fetch_env!(:guesty, :api_url)
end
