defmodule Guesty.TasksPerformer do
  @moduledoc """
  Tasks performer for Guesty channel
  """

  use Broadway

  require Logger

  alias Broadway.Message
  alias Guesty.Actions

  @module_name inspect(__MODULE__)
  @queue "guesty_tasks"
  @timeout :timer.seconds(10)

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          producer(),
          queue: @queue,
          declare: [
            durable: true
          ],
          connection: connection(),
          on_failure: :reject_and_requeue,
          qos: [prefetch_count: 10]
        },
        concurrency: 2
      ],
      processors: [
        default: [concurrency: 2]
      ]
    )
  end

  @impl true
  def handle_message(:default, message, _context) do
    Logger.info("#{@module_name} handle_message")

    with {:ok, payload} <-
           MessageQueue.decode_data(message.data, parser_opts: [keys: :atoms]),
         {:ok, _} <- perform_task(payload) do
      message
    else
      _error ->
        message
        |> Message.configure_ack(on_failure: :reject_and_requeue)
        |> Message.failed(:unknown_error)
    end
  end

  @impl true
  def handle_failed(message, _context) do
    Process.sleep(@timeout)
    message
  end

  defp perform_task(%{hotel_code: hotel_code, status: "enable"}),
    do: Actions.enable_push(hotel_code)

  defp perform_task(%{hotel_code: hotel_code, status: "disable"}),
    do: Actions.disable_push(hotel_code)

  defp perform_task(%{status: "full_sync"} = args), do: Actions.full_sync(args)

  defp producer, do: Application.fetch_env!(:guesty, :broadway_producer_module)
  defp connection, do: Application.fetch_env!(:message_queue, :connection)
end
