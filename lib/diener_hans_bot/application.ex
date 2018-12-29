defmodule DienerHansBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: DienerHansBot.Worker.start_link(arg)
      # {DienerHansBot.Worker, arg},
      worker(DienerHansBot.ReminderSender, []),
      worker(DienerHansBot.ReminderClock, []),
      worker(DienerHansBot.CommandReceiver, [])

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DienerHansBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
