defmodule Guesty.BookingFetcher do
  @moduledoc false

  use GenServer

  require Logger

  alias Guesty.Actions

  @fetch_interval :timer.minutes(10)

  @doc false
  def start_link(init_arg) do
    opts = [name: __MODULE__, hibernate_after: 15_000]

    with {:ok, pid} <- GenServer.start_link(__MODULE__, init_arg, opts) do
      Logger.info("Guesty BookingFetcher started")
      {:ok, pid}
    end
  end

  @impl true
  def init(init_args) do
    {:ok, _} = :timer.send_interval(@fetch_interval, :fetch_bookings)
    {:ok, init_args}
  end

  @impl true
  def handle_info(:fetch_bookings, state) do
    Logger.info("Guesty BookingFetcher fetch bookings")
    Actions.retrieve_bookings()
    {:noreply, state}
  end
end
