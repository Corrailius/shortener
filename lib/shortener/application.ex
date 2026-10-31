defmodule Shortener.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    db = System.get_env("DB_PATH") || Application.get_env(:shortener, :db_path, "shortener.db")

    children = [{Shortener.Repo, database: db, pool_size: 1}] ++ web_children()

    with {:ok, sup} <-
           Supervisor.start_link(children, strategy: :one_for_one, name: Shortener.Supervisor) do
      Shortener.Store.setup()
      {:ok, sup}
    end
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
