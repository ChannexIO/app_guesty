defmodule Guesty.Cache do
  @moduledoc """
  Cache for Guesty.
  """

  defstruct retrieval_retries: 0

  @module_name inspect(__MODULE__)
  @settings_table Module.concat(__MODULE__, Settings)

  use GenServer

  require Logger

  alias Guesty.{Actions, Cache}
  alias Guesty.DTO.Settings

  @retry_timeout :timer.seconds(5)
  @exponential_modifier 2
  @max_retrieval_retries 9

  defguardp is_valid_settings(settings)
            when is_map(settings) and is_map_key(settings, "property_id") and
                   is_map_key(settings, "listingId")

  defguard presence_code(property_id) when property_id != "" and not is_nil(property_id)

  @doc """
  Get settings by listing_id
  """
  @spec get_by_code(term()) :: {:ok, nil | map() | list(map())} | {:error, :invalid_arguments}
  def get_by_code(id) when is_binary(id) do
    case :ets.lookup(@settings_table, id) do
      [{_, _, settings}] -> {:ok, settings}
      [] -> {:ok, nil}
    end
  end

  def get_by_code([]), do: {:ok, []}

  def get_by_code(ids) when is_list(ids) do
    id_condition = Enum.map(ids, &{:==, :"$1", &1})
    condition = List.to_tuple([:or] ++ id_condition)
    {:ok, :ets.select(@settings_table, [{{:"$1", :_, :"$3"}, [condition], [:_, :_, :"$3"]}])}
  end

  def get_by_code(_), do: {:error, :invalid_arguments}

  @doc """
  Get settings by property id.
  """
  @spec get_by_id(term()) :: {:ok, nil | map() | list(map())}
  def get_by_id(id) do
    match_spec = [{{:"$1", :"$2", :"$3"}, [{:==, :"$2", id}], [:"$3"]}]

    case :ets.select(@settings_table, match_spec) do
      [settings] -> {:ok, settings}
      [] -> {:ok, nil}
      settings -> {:ok, settings}
    end
  end

  @doc """
  Get all settings.
  """
  @spec all() :: {:ok, list(map())}
  def all do
    {:ok, :ets.select(@settings_table, [{{:"$1", :"$2", :"$3"}, [], [:"$3"]}])}
  end

  @doc """
  Get all settings lazily.
  """
  @spec stream_all() :: Enumerable.t()
  def stream_all do
    Stream.resource(&stream_all_settings/0, &stream_all_settings/1, &Function.identity/1)
  end

  @doc """
  Fill cache by list of installations
  """
  def fill(installations) do
    insert_settings(installations)
  end

  @doc """
  Removes settings from cache
  """
  @spec remove(map()) :: :ok
  def remove(settings) do
    remove_settings(settings)
  end

  @doc """
  Fills settings  cache
  """
  def fill_cache(data) do
    GenServer.cast(__MODULE__, {:fill_cache, data})
  end

  @doc """
  Update settings at cache
  """
  def update(settings) do
    insert_settings(settings)
  end

  @doc false
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__, hibernate_after: 15_000)
  end

  @impl true
  def init(init_arg) do
    case init_arg[:is_active] do
      true ->
        Logger.info("#{@module_name} started")
        :ets.new(@settings_table, [:named_table, :public, read_concurrency: true])
        {:ok, update_state(__MODULE__, []), {:continue, :get_installations}}

      _ ->
        :ignore
    end
  end

  @impl true
  def handle_cast({:fill_cache, installations}, state) do
    Logger.info("#{@module_name} data received")
    Cache.fill(installations)
    {:noreply, reset_retries(state)}
  end

  @impl true
  def handle_continue(:get_installations, state) do
    Logger.info("#{@module_name} data retrieval")
    get_installations()
    {:noreply, state, set_timeout(state)}
  end

  @impl true
  def handle_info(:timeout, %{retrieval_retries: retries} = state)
      when retries >= @max_retrieval_retries do
    Logger.error("#{@module_name} data retrieval failed")
    {:noreply, reset_retries(state)}
  end

  @impl true
  def handle_info(:timeout, state) do
    state = increment_retries(state)
    Logger.info("#{@module_name} data retrieval failed, attempt ##{state.retrieval_retries + 1}")
    get_installations()
    {:noreply, state, set_timeout(state)}
  end

  defp insert_settings(settings) when is_list(settings) do
    Enum.each(settings, &insert_settings/1)
  end

  defp insert_settings(settings) when is_map(settings) do
    case prepare_settings(settings) do
      {listing_id, property_id, _settings}
      when is_nil(listing_id) or is_nil(property_id) or listing_id == "" or property_id == "" ->
        :ok

      settings ->
        :ets.insert(@settings_table, settings)
        :ok
    end
  end

  defp prepare_settings(settings) when is_map(settings) do
    {settings["listingId"], settings["property_id"], Settings.build(settings)}
  end

  defp remove_settings(settings) when is_valid_settings(settings) do
    :ets.delete(@settings_table, settings["hotelCode"])
    :ok
  end

  defp remove_settings(settings) when is_map_key(settings, :listing_id) do
    :ets.delete(@settings_table, settings.listing_id)
    :ok
  end

  defp stream_all_settings, do: :ets.match(@settings_table, {:_, :_, :"$1"}, 10)
  defp stream_all_settings(:"$end_of_table"), do: {:halt, nil}
  defp stream_all_settings({settings, cont}), do: {Enum.concat(settings), :ets.match(cont)}

  defp get_installations do
    Task.start(Actions, :get_installations, [])
  end

  defp set_timeout(%{retrieval_retries: retries}) do
    round(@retry_timeout * Integer.pow(@exponential_modifier, retries))
  end

  defp update_state(state, data), do: struct!(state, data)

  defp reset_retries(state), do: update_state(state, retrieval_retries: 0)

  defp increment_retries(%{retrieval_retries: retries} = state) do
    update_state(state, retrieval_retries: retries + 1)
  end
end
