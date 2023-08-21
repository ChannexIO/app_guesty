defmodule Guesty.Actions.PushBookings do
  @moduledoc false

  require Logger

  alias Guesty.{Actions, MessageConverter, Services.AvailabilityChecker}

  @type args() :: term()
  @type response() :: {:ok | :error, %{success: boolean()}}

  @doc false
  def perform(init_args) do
    with {:ok, args} <- compose_args(init_args),
         {:ok, response} <- get_bookings(args),
         {:ok, attrs} <- extract_attrs(response),
         {:ok, message} <- convert_attrs(attrs),
         {:ok, _} <- AvailabilityChecker.check(message),
         {:ok, response, _meta} <- send_booking(message) do
      {:ok, put_revision_id(response, attrs)}
    else
      error -> check_error(error, init_args)
    end
  end

  defp compose_args(%{booking: booking}), do: {:ok, %{booking: booking}}
  defp compose_args(%{booking_id: booking_id}), do: {:ok, %{booking_id: booking_id}}
  defp compose_args(%{revision_id: revision_id}), do: {:ok, %{revision_id: revision_id}}
  defp compose_args(%{unique_id: unique_id}), do: {:ok, %{unique_id: unique_id}}

  defp compose_args(%{"payload" => %{"booking_id" => booking_id}}) do
    {:ok, %{booking_id: booking_id}}
  end

  defp compose_args(_args), do: {:error, :invalid_args}

  defp get_bookings(%{booking: booking}), do: {:ok, booking}

  defp get_bookings(args) do
    %{headers: [user_api_key: user_api_key()], method: :get, endpoint: compose_endpoint(args)}
    |> requester().new()
    |> requester().perform()
    |> prepare_response()
  end

  defp compose_endpoint(%{booking_id: booking_id}), do: "bookings/#{booking_id}"
  defp compose_endpoint(%{revision_id: revision_id}), do: "booking_revisions/#{revision_id}"
  defp compose_endpoint(%{unique_id: unique_id}), do: "bookings?" <> encode_query(unique_id)

  defp encode_query(unique_id) do
    URI.encode_query(%{"filter[unique_id]" => unique_id, "pagination[limit]" => 1})
  end

  defp prepare_response({:ok, response, _meta}), do: {:ok, response}
  defp prepare_response({:network_error, error, _meta}), do: {:error, error}
  defp prepare_response({:error, error, _meta}), do: {:error, error}

  defp extract_attrs(%{"data" => []}), do: {:error, :no_bookings}
  defp extract_attrs(%{"data" => %{"attributes" => attrs}}), do: {:ok, attrs}
  defp extract_attrs(%{"data" => [%{"attributes" => attrs}]}), do: {:ok, attrs}
  defp extract_attrs(%{"attributes" => attrs}), do: {:ok, attrs}
  defp extract_attrs(attrs), do: {:ok, attrs}

  defp convert_attrs(attrs) do
    {:ok, MessageConverter.convert(attrs)}
  end

  defp send_booking(message) do
    Actions.push_reservations(message)
  end

  defp put_revision_id(response, %{"revision_id" => id}), do: Map.put(response, :id, id)
  defp put_revision_id(response, %{"id" => id}), do: Map.put(response, :id, id)

  defp check_error(error, args) do
    Logger.error(ctx: __MODULE__, args: args, error: error)

    error
    |> extract_error()
    |> clasify_error()
    |> case do
      :temporary_error -> {:error, %{success: false}}
      :permanent_error -> {:ok, %{success: false}}
    end
  end

  defp extract_error({:error, error}), do: error
  defp extract_error({:error, error, _meta}), do: error

  defp clasify_error(:no_booking), do: :permanent_error
  defp clasify_error(:invalid_args), do: :permanent_error
  defp clasify_error(%{"errors" => %{"code" => "bad_request"}}), do: :permanent_error
  defp clasify_error(%{"errors" => %{"code" => "resource_not_found"}}), do: :permanent_error
  defp clasify_error(%{"errors" => %{"code" => "unauthorized"}}), do: :permanent_error
  defp clasify_error(_error), do: :temporary_error

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp user_api_key, do: Application.fetch_env!(:guesty, :user_api_key)
end
