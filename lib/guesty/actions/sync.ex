defmodule Guesty.Actions.Sync do
  @moduledoc false

  import Guesty.Actions.Helper

  alias __MODULE__.{Request, Response}
  alias Guesty.DTO.Schemes.ARI, as: ARISchema
  alias Guesty.ChangesConverter

  @type args() :: map()
  @type response() :: {:ok, term()} | {:error, term(), term()}

  def perform(args) do
    args
    |> validate(ARISchema.get())
    |> ChangesConverter.convert()
    |> Request.execute()
    |> Response.parse()
  end
end
