defmodule Guesty.DTO.Settings do
  @moduledoc false

  use Guesty.DTO

  defstruct listing_id: nil,
            property_id: nil,
            room_types: nil

  @spec build(map()) :: t()
  def build(settings) do
    {listing_id, settings} = Map.pop(settings, "listingId")
    {property_id, settings} = Map.pop(settings, "property_id")

    new(%{
      listing_id: listing_id,
      property_id: property_id,
      room_types: compose_room_types(settings)
    })
  end

  defp compose_room_types(room_types) do
    for {id, %{"code" => code, "title" => title, "ratePlans" => rate_plans}} <- room_types,
        into: %{} do
      {to_string(code), %{id: id, title: title, rate_plans: compose_rate_plans(rate_plans)}}
    end
  end

  defp compose_rate_plans(rate_plans) do
    rate_plans
    |> Enum.group_by(fn {_, %{"code" => code}} -> to_string(code) end, fn {id,
                                                                           %{
                                                                             "title" => title,
                                                                             "settings" =>
                                                                               settings
                                                                           }} ->
      %{
        id: id,
        title: title,
        occupancy: to_string(settings["occupancy"]),
        primary: settings["primary"]
      }
    end)
  end

  defimpl String.Chars, for: __MODULE__ do
    def to_string(setting) do
      setting
      |> Map.from_struct()
      |> Jsonrs.encode!()
    end
  end
end
