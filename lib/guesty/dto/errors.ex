defmodule Guesty.DTO.Errors do
  use Guesty.DTO

  require Logger

  @error_status "Fail"

  defstruct [:status, :error_desc, :tracking_id]

  @errors %{
    "1" => %{error_desc: "Bad Request", status: 400},
    "2" => %{error_desc: "Unauthorized", status: 401},
    "3" => %{error_desc: "Forbidden", status: 401},
    "4" => %{error_desc: "Unable to parse response", status: 500},
    "5" => %{error_desc: "Network error", status: 500},
    "6" => %{error_desc: "Internal system error", status: 500}
  }

  @doc false
  def transform(error, meta) do
    formed_error =
      error
      |> format(meta)
      |> update(tracking_id: get_request_id(meta))

    %{status: formed_error.status, payload: %{formed_error | status: @error_status}}
  end

  defp format(:unmapped_room, %{code: room_type_code}),
    do: compose_error("1", "Unmapped room with code: #{room_type_code}")

  defp format(:unmapped_rate, %{code: rate_plan_code}),
    do: compose_error("1", "Unmapped rate with code: #{rate_plan_code}")

  defp format(error, _), do: format(error)

  defp format(message) when is_binary(message) do
    compose_error("1", message)
  end

  defp format(details) when is_list(details) do
    message = Enum.map_join(details, ", ", &get_error_details/1)
    compose_error("1", message)
  end

  defp format(%{"code" => "bad_request", "details" => details}) when is_map(details) do
    message = Enum.map_join(details, ", ", &get_error_details/1)
    compose_error("1", message)
  end

  defp format(:no_settings), do: compose_error("1", "Property Not Active")
  defp format(%{"code" => "bad_request"}), do: compose_error("1")
  defp format(%{"code" => "unauthorized"}), do: compose_error("2")
  defp format(%{"code" => "forbidden"}), do: compose_error("3")

  defp format(%Jason.DecodeError{} = error) when is_exception(error) do
    compose_error("4", Exception.message(error))
  end

  defp format(%{code: "network_error", message: message}) do
    compose_error("5", message)
  end

  defp format(error) do
    Logger.error(ctx: __MODULE__, error: error)
    compose_error("6", "Internal Server Error from Partner, unable to process")
  end

  defp compose_error(type, desc \\ nil) do
    @errors
    |> Map.get(type)
    |> new()
    |> update_desc(desc)
  end

  defp update_desc(error, nil), do: update(error, error_desc: error.error_desc)
  defp update_desc(error, ""), do: update(error, error_desc: error.error_desc)
  defp update_desc(error, desc), do: update(error, error_desc: desc)

  defp get_error_details(error) when is_map(error) do
    Enum.map_join(error, ", ", &get_error_details/1)
  end

  defp get_error_details({field, errors}) when is_list(errors),
    do: "#{field} #{Enum.join(errors, ", ")}"

  defp get_error_details({field, error}), do: "#{field} #{error}"

  defp get_request_id do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.url_encode64(binary)
  end

  defp get_request_id(%{headers: headers}) when is_list(headers) do
    with {_, request_id} <- List.keyfind(headers, "x-request-id", 0) do
      request_id
    else
      _ -> get_request_id()
    end
  end

  defp get_request_id(_), do: get_request_id()
end
