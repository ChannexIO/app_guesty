defmodule Guesty.Actions.Helper do
  @moduledoc false

  @doc """
  Validate args
  """
  @spec validate(map(), ExJsonSchema.Schema.Root.t()) :: {:ok, map()} | {:error, term()}
  def validate(args, schema) do
    with :ok <- ExJsonSchema.Validator.validate(schema, args) do
      {:ok, args}
    end
  end
end
