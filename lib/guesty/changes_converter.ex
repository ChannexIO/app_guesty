defmodule Guesty.ChangesConverter do
  @moduledoc false

  require Logger

  alias Guesty.Cache

  @doc false
  def convert({:ok, args}) when is_map(args) do
    with {:ok, settings} when not is_nil(settings) <- Cache.get_by_code(args["propertyid"]) do
      {:ok, compose_changes(args, settings)}
    else
      {:ok, nil} ->
        log_error("no settings", args)
        {:error, :no_settings}

      error ->
        error
    end
  end

  def convert({:error, error}), do: {:error, error}

  defp compose_changes(message, settings) do
    availability = compose_availability(message, settings)
    restrictions = compose_restrictions(message, settings)

    Enum.reduce(message, %{availability: [], restrictions: []}, fn data, acc ->
      availability = compose_availability(data, settings)
      restrictions = compose_restrictions(data, settings)

      acc
      |> Map.update!(:availability, &Enum.concat(&1, availability))
      |> Map.update!(:restrictions, &Enum.concat(&1, restrictions))
    end)
  end

  defp compose_availability(%{"roomLevelMessages" => inventories} = message, settings) do
    for %{"invTypeCode" => code} = inventory <- inventories do
      %{
        date_from: inventory["start"],
        date_to: inventory["end"],
        availability: prepare_value(inventory["bookingLimit"]),
        room_type_id: Map.get(settings.room_types, code, code)
      }
    end
  end

  defp compose_availability(_, _), do: []

  defp compose_restrictions(message, settings) do
  end

  defp compose_restrictions(data, settings) do
    Enum.map(settings.rates, fn %{occupancy: occupancy, id: rate_plan_id} ->
      data
      |> unit_ari_change(settings)
      |> Map.put(:rate_plan_id, rate_plan_id)
      |> Map.merge(extract_restrictions(data))
      |> merge_rate_by_occupancy(data, occupancy)
    end)
  end

  defp merge_rate_by_occupancy(changes, data, occupancy) do
    for {"person" <> ^occupancy, rate} <- get_rate_amounts(data), into: %{} do
      {:rate, prepare_rate(rate)}
    end
    |> Map.merge(changes)
  end

  defp extract_restrictions(data) do
    Enum.reduce(data, %{}, fn {restriction, value}, changes ->
      add_change(changes, restriction, prepare_value(value))
    end)
  end

  defp get_rate_amounts(%{"amountAfterTax" => %{"obp" => obp}}), do: obp
  defp get_rate_amounts(%{"amountBeforeTax" => %{"obp" => obp}}), do: obp
  defp get_rate_amounts(_), do: %{}

  defp add_change(changes, "stopsell", value), do: Map.put(changes, :stop_sell, value)
  defp add_change(changes, "cta", value), do: Map.put(changes, :closed_to_arrival, value)
  defp add_change(changes, "ctd", value), do: Map.put(changes, :closed_to_departure, value)
  defp add_change(changes, "minstay", 0), do: Map.put(changes, :min_stay_arrival, 1)
  defp add_change(changes, "minstay", value), do: Map.put(changes, :min_stay_arrival, value)
  defp add_change(changes, "maxstay", value), do: Map.put(changes, :max_stay, value)
  defp add_change(changes, _, _), do: changes

  defp prepare_value("Y"), do: true
  defp prepare_value("N"), do: false
  defp prepare_value(value) when is_integer(value), do: value

  defp prepare_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed_value, _} -> parsed_value
      :error -> value
    end
  end

  defp prepare_value(value), do: value

  defp prepare_rate(value) when is_integer(value), do: value
  defp prepare_rate(value), do: to_string(value)

  defp unit_ari_change(data, settings, options \\ %{}) do
    %{
      property_id: settings.property_id,
      room_type_id: settings.room_type_id
    }
    |> add_date_from_to(data)
    |> Map.merge(options)
  end

  defp add_date_from_to(changes, %{"from_date" => _} = data) do
    changes
    |> Map.merge(%{date_from: data["from_date"], date_to: data["to_date"]})
  end

  defp add_date_from_to(changes, %{"date" => _} = data) do
    changes
    |> Map.merge(%{date_from: data["date"], date_to: data["date"]})
  end

  defp log_error(error, args) do
    Logger.error(ctx: __MODULE__, args: args, error: error)
  end
end
