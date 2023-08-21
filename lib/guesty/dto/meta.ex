defmodule Guesty.DTO.Meta do
  @moduledoc false

  use Guesty.DTO

  defstruct request: nil,
            response: nil,
            status_code: nil,
            method: nil,
            headers: nil,
            started_at: nil,
            finished_at: nil,
            errors: [],
            warnings: []
end
