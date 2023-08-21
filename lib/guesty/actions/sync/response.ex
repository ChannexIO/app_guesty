defmodule Guesty.Actions.Sync.Response do
  @moduledoc false

  @doc false
  def parse({:ok, %{errors: []}}) do
    {:ok, %{status: "success", error_desc: ""}}
  end

  def parse({:error, %{errors: errors}}) when is_list(errors) do
    errors
    |> Enum.uniq()
    |> then(fn errors -> {:error, errors} end)
  end

  def parse({:error, %{errors: error}}), do: {:error, error}
  def parse(error), do: error
end
