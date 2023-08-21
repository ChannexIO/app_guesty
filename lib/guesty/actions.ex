defmodule Guesty.Actions do
  @moduledoc """
  Actions of the channel necessary for its operational work.
  """

  alias __MODULE__.{
    AckBooking,
    GetInstallations,
    MappingDetails,
    PushBookings,
    PushReservations,
    RetrieveBookings,
    Sync
  }

  @spec ack_booking(AckBooking.args()) :: AckBooking.response()
  def ack_booking(args) do
    AckBooking.perform(args)
  end

  @spec mapping_details(MappingDetails.args()) :: MappingDetails.response()
  def mapping_details(args) do
    MappingDetails.perform(args)
  end

  @spec get_installations() :: GetInstallations.response()
  def get_installations do
    GetInstallations.perform()
  end

  @spec push_bookings(PushBookings.args()) :: PushBookings.response()
  def push_bookings(args) do
    PushBookings.perform(args)
  end

  @spec push_reservations(PushReservations.args()) :: PushReservations.response()
  def push_reservations(args) do
    PushReservations.perform(args)
  end

  @spec retrieve_bookings() :: RetrieveBookings.response()
  def retrieve_bookings do
    RetrieveBookings.perform()
  end

  @spec sync(Sync.args()) :: Sync.response()
  def sync(args) do
    Sync.perform(args)
  end
end
