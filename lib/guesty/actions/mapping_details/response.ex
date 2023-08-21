defmodule Guesty.Actions.MappingDetails.Response do
  @moduledoc false

  require Logger

  @doc false
  def parse({:ok, response}) do
    {:ok,
     %{
       data: %{
         type: "mapping_details",
         attributes: %{
           room_types: compose_mappings(response)
         }
       }
     }}
  end

  def parse(error), do: error

  defp compose_mappings(%{listing: listing, rate_plans: rate_plans}) do
    %{
      id: listing["_id"],
      title: listing["title"],
      rate_plans: compose_rate_plans(rate_plans)
    }
  end

  defp compose_rate_plans(rate_plans) do
    Enum.map(rate_plans["RatePlans"], fn rate_plan ->
      %{
        id: rate_plan["RatePlan"]["Code"],
        title: rate_plan["RatePlan"]["Name"],
        sell_mode: :per_room
      }
    end)
  end
end
