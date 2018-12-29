defmodule DienerHansBot.ReminderSender do
  alias DienerHansBot.Reminder
  use GenServer
  require Logger

  defmodule ServerImpl do

    def send_now(%{chat_id: chat_id, message: message} = reminder) do
      Logger.debug fn -> {"[#{__MODULE__}] Sending reminder: #{inspect(reminder)}", []} end 

      # TODO: make reminder look nicer
      Nadia.send_message(chat_id, "i want to remind you of ...")
      Nadia.send_message(chat_id, message)

    end
  end

  # client
  def start_link do
    state = {}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def send_now(%Reminder{} = reminder) do
    GenServer.cast(__MODULE__, {:send_now, reminder})
  end

  # Server callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:send_now, reminder}, state) do
    ServerImpl.send_now(reminder)

    {:noreply, state}
  end
end
