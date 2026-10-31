defmodule Shortener.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [Shortener.Store] ++ web_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: Shortener.Supervisor)
  end

  defp web_children do
    if Application.get_env(:shortener, :start_server, true) do
      port = String.to_integer(System.get_env("PORT", "4000"))
      [{Bandit, plug: Shortener.Router, port: port}]
    else
      []
    end
  end
end
