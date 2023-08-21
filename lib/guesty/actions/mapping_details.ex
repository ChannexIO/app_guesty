defmodule Guesty.Actions.MappingDetails do
  @moduledoc false

  alias __MODULE__.{Request, Response}

  @type hotel_code() :: map()
  @type response() :: {:ok, map()} | {:error, term(), term()}

  def perform(args) do
    args
    |> Request.execute()
    |> Response.parse()
  end
end
