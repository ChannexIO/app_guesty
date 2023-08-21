defmodule Guesty.MessageConverter do
  @moduledoc false

  @statuses %{"new" => "Confirm", "cancelled" => "Cancel", "modified" => "Modified"}
  @payment_types %{"property" => "Hotel Collect", "ota" => "Channel Collect"}
  @pos "Reserva"

  require Logger

  alias Guesty.Cache

  @spec convert(map()) :: map()
  def convert(args) do
    case Cache.get_by_id(args["property_id"]) do
      {:ok, nil} ->
        log_error(args, "no settings")
        nil

      {:ok, settings} ->
        %{reservation: compose_reservation(args, settings)}
        |> Map.put(:property_id, settings.hotel_code)
        |> Map.put(:token, args["guarantee"]["token"])
    end
  end

  defp compose_reservation(args, settings) do
    %{
      reservation_datetime: args["inserted_at"],
      reservation_id: args["ota_reservation_code"],
      totalamountaftertax: args["amount"],
      totaltax: set_total_tax(args["rooms"]),
      currencycode: args["currency"],
      status: @statuses[args["status"]],
      customer: set_customer(args["customer"]),
      room: set_room(args, settings),
      POS: @pos,
      payment_type: @payment_types[args["payment_collect"]]
    }
    |> put_unless_nil(:paymentcarddetail, set_payment_detail(args["guarantee"]))
  end

  defp set_total_tax(rooms) do
    for %{"taxes" => taxes} <- rooms, tax <- taxes, reduce: 0 do
      total -> total + parse_price(tax["total_price"])
    end
  end

  defp set_payment_detail(%{"token" => token} = guarantee) when not is_nil(token) do
    %{
      CardHolderName: "%CARDHOLDER_NAME%",
      CardType: guarantee["card_type"],
      ExpireDate: guarantee["expiration_date"],
      CardNumber: "%CARD_NUMBER%",
      cvv: "%SERVICE_CODE%"
    }
  end

  defp set_payment_detail(_), do: nil

  defp set_customer(customer) do
    %{
      first_name: customer["name"] || customer["surname"],
      last_name: customer["surname"]
    }
    |> put_unless_nil(:address, customer["address"])
    |> put_unless_nil(:city, customer["city"])
    |> put_unless_nil(:country, customer["country"])
    |> put_unless_nil(:email, customer["mail"])
    |> put_unless_nil(:telephone, customer["phone"])
    |> put_unless_nil(:zip, customer["postalCode"])
  end

  defp set_room(args, settings) do
    for room <- args["rooms"] do
      mapping = get_mapping(room, settings.room_types)
      {first_name, last_name} = get_guest_name(room, args)

      %{
        arrival_date: room["checkin_date"],
        departure_date: room["checkout_date"],
        room_id: mapping[:room_code],
        first_name: first_name,
        last_name: last_name,
        price: set_room_price(room, mapping),
        amountaftertax: room["amount"],
        GuestCount: set_occupancy(room["occupancy"]),
        taxes: set_taxes(room["taxes"])
      }
    end
  end

  defp set_room_price(room, mapping) do
    for {date, price} <- room["days"] do
      %{
        date: date,
        rate_id: mapping[:rate_code],
        amountaftertax: price
      }
    end
  end

  defp set_taxes(taxes) do
    for tax <- taxes do
      %{
        "name" => tax["name"],
        "value" => tax["total_price"]
      }
    end
  end

  defp get_guest_name(%{"guests" => guests}, %{"customer" => customer}) do
    guest = guests |> List.wrap() |> List.first()
    {guest["name"] || customer["name"], guest["surname"] || customer["surname"]}
  end

  defp get_mapping(room, room_types) do
    for {room_code, %{id: room_type_id, rate_plans: rate_plans}} <- room_types,
        room_type_id == room["room_type_id"],
        {rate_code, rates} <- rate_plans,
        %{id: rate_plan_id} <- rates,
        rate_plan_id == room["rate_plan_id"],
        reduce: %{} do
      acc -> Map.merge(acc, %{room_code: room_code, rate_code: rate_code})
    end
  end

  defp set_occupancy(occupancy) do
    [
      %{
        AgeQualifyingCode: "10",
        Count: occupancy["adults"]
      },
      %{
        AgeQualifyingCode: "8",
        Count: occupancy["children"]
      }
    ]
  end

  defp put_unless_nil(data, _key, nil), do: data
  defp put_unless_nil(data, _key, ""), do: data
  defp put_unless_nil(data, key, value), do: Map.put(data, key, value)

  defp parse_price(price) when is_integer(price), do: price

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {price, _} ->
        price

      _ ->
        log_error(price, "invalid price")
        0
    end
  end

  defp log_error(args, error) do
    Logger.error(ctx: __MODULE__, args: args, error: error)
  end
end
