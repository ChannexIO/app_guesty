defmodule Guesty.Actions.GetInstallations do
  @moduledoc false

  require Logger

  alias Guesty.Cache

  @type response() :: {:ok, term()} | {:error, term()}

  @application_code "guesty"

  @doc false
  def perform do
    with {:ok, response} <- send_request(),
         {:ok, response} <- format_response(response),
         :ok <- Cache.fill_cache(response) do
      {:ok, response}
    else
      error -> log_error(error)
    end
  end

  defp send_request do
    %{method: :get, headers: [user_api_key: user_api_key()], endpoint: "applications/installed"}
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp format_response(%{"data" => attrs}), do: {:ok, compose_installations(attrs)}
  defp format_response(response), do: {:error, response}

  defp compose_installations(attrs) do
    for %{
          "attributes" => %{
            "application_code" => @application_code,
            "property_id" => property_id,
            "settings" => settings
          }
        } <- attrs,
        is_map(settings) do
      Map.put(settings, "property_id", property_id)
    end
  end

  defp log_error(error) do
    Logger.error(ctx: __MODULE__, error: error)
    error
  end

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp user_api_key, do: Application.fetch_env!(:guesty, :user_api_key)
end
