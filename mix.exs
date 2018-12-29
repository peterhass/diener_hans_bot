defmodule DienerHansBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :diener_hans_bot,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DienerHansBot.Application, []},
      application: [:nadia, :timex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # telegram bot api wrapper
      {:nadia, "~> 0.4.4"},

      # A complete date/time library for Elixir projects. https://hexdocs.pm/timex
      {:timex, "~> 3.1"}
    ]
  end
end
