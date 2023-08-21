defmodule Guesty.Actions.Sync.Request do
  @moduledoc false

  @request_timeout :timer.seconds(60)

  @doc false
  def execute({:ok, args}) do
    args
    |> perform_requests()
  end

  def execute(error), do: error

  defp perform_requests(payload) do
    task_opts = [
      max_concurrency: map_size(payload),
      timeout: @request_timeout,
      on_timeout: :kill_task,
      ordered: false
    ]

    state = %{errors: []}

    payload
    |> Task.async_stream(&perform_request/1, task_opts)
    |> Enum.reduce_while({:ok, state}, &format_task_response/2)
  end

  defp perform_request({_endpoint, []}), do: {:ok, :no_changes}

  defp perform_request({endpoint, payload}) do
    [
      endpoint: to_string(endpoint),
      headers: [user_api_key: user_api_key()],
      payload: {:json, %{values: payload}}
    ]
    |> requester().new()
    |> requester().perform()
  end

  defp format_task_response({:ok, result}, acc) do
    case result do
      {:ok, :no_changes} -> {:cont, acc}
      {:ok, result, _meta} -> {:cont, check_result(result, acc)}
      {:error, error, _meta} -> {:halt, check_result(error, acc)}
      {:network_error, error, _meta} -> {:halt, check_result(error, acc)}
    end
  end

  defp format_task_response({:exit, error}, _acc) do
    error = %{code: "network_error", message: error}
    {:halt, {:error, %{errors: error}}}
  end

  defp check_result(%{"meta" => %{"warnings" => [warning | _]}}, {_, acc}),
    do: {:error, append_value(acc, :errors, warning["warning"])}

  defp check_result(%{"meta" => %{"message" => "Success"}}, {resolution, acc}),
    do: {resolution, acc}

  defp check_result(%{"errors" => errors}, {_, acc}),
    do: {:error, append_value(acc, :errors, errors)}

  defp check_result(error, _), do: {:error, error}

  defp append_value(acc, _key, nil), do: acc
  defp append_value(acc, key, value), do: Map.update!(acc, key, &add_value(&1, value))

  defp add_value(data, values) when is_list(values), do: Enum.concat(values, data)
  defp add_value(data, value), do: [value | data]

  defp requester, do: Application.fetch_env!(:guesty, :requester)
  defp user_api_key, do: Application.fetch_env!(:guesty, :user_api_key)
end
