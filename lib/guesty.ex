defmodule Guesty do
  @moduledoc """
  Documentation for `Guesty`.
  """

  alias __MODULE__.Actions

  defdelegate sync(args), to: Actions
  defdelegate ack_booking(args), to: Actions
  defdelegate push_bookings(args), to: Actions
  defdelegate mapping_details(args), to: Actions
end
