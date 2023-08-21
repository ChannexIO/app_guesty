defmodule Guesty.DTO do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @type t() :: %__MODULE__{}
      @typep data() :: t() | Enumerable.t()

      @spec new(data()) :: t()
      def new(data \\ [])
      def new(%{__struct__: __MODULE__} = struct), do: struct
      def new(data), do: struct(__MODULE__, data)

      @spec new!(data()) :: t()
      def new!(%{__struct__: __MODULE__} = struct), do: struct
      def new!(data), do: struct!(__MODULE__, data)

      @spec update(t(), Enumerable.t()) :: t()
      def update(struct, data \\ %{}), do: struct(struct, data)
    end
  end
end
