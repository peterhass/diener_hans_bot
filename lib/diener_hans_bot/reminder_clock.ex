defmodule DienerHansBot.ReminderClock do
  alias DienerHansBot.Reminder
  alias DienerHansBot.ReminderSender
  require Logger
  use Task
  use GenServer

  defmodule Job do
    defstruct [:run_at, :type, :payload]
  end

  defmodule ServerImpl do
    def init_state, do: %{jobs: []}

    def add_reminder(state, %Reminder{date: run_at} = reminder) do
      Logger.debug fn -> "[#{__MODULE__}] Schedule reminder for #{DateTime.to_string(run_at)}: #{inspect(reminder)}" end
      add_job(state, %Job{run_at: run_at, type: :reminder, payload: reminder})
    end

    def add_job(%{jobs: jobs} = state, %Job{} = job) do
      new_jobs =
        (jobs ++ [job])
        |> Enum.sort_by(&(&1.run_at), &(DateTime.compare(&1, &2) == :gt))

      {:ok, %{state | jobs: new_jobs}}
    end

    # pops all overdue jobs
    def pop_jobs(%{jobs: jobs} = state, datetime) do
      {jobs, remaining_jobs} = _pop_jobs([], jobs, datetime)

      {%{state | jobs: remaining_jobs}, jobs}
    end

    defp _pop_jobs(result, jobs, datetime) do
      {job, remaining_jobs} = List.pop_at(jobs, 0)

      if is_job_due(job, datetime) do
        _pop_jobs(result ++ [job], remaining_jobs, datetime)
      else
        {result, jobs}
      end
    end

    defp is_job_due(job, _datetime) when is_nil(job), do: false
    defp is_job_due(%{run_at: run_at}, datetime), do: DateTime.compare(datetime, run_at) == :gt

    def send_pending_reminder(state, datetime) do
      {new_state, pending_jobs} = pop_jobs(state, datetime)

      pending_jobs
      |> Enum.each(&(ReminderSender.send_now(&1.payload)))

      {:ok, new_state}
    end
  end

  # Client callbacks
  def start_link do
    GenServer.start_link(__MODULE__, ServerImpl.init_state, name: __MODULE__)
  end

  def schedule_reminder(%Reminder{} = reminder) do
    GenServer.cast(__MODULE__, {:schedule_reminder, reminder})
  end

  # Server callbacks
  @impl true
  def init(state) do
    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    {:ok, new_state} = ServerImpl.send_pending_reminder(state, DateTime.utc_now)

    schedule_tick()
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:schedule_reminder, reminder}, state) do
    {:ok, new_state} = ServerImpl.add_reminder(state, reminder)
    {:noreply, new_state}
  end

  defp schedule_tick() do
    Process.send_after(self(), :work, 1_000)
  end
end
