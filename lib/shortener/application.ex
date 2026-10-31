defmodule Shortener.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT", "4000"))

    children = [
      Shortener.Store,
      {Bandit, plug: Shortener.Router, port: port}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Shortener.Supervisor)
  end
end
