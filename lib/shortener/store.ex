defmodule Shortener.Store do
  use Agent

  alias Shortener.Repo

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def setup do
    path = Application.app_dir(:shortener, "priv/repo/migrations")

    if File.dir?(path) do
      Ecto.Migrator.run(Shortener.Repo, path, :up, all: true)
    else
      Repo.query!("CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT NOT NULL)")
    end
  end

  def put(url) do
    code = generate_unique_code()
    Repo.query!("INSERT INTO links (code, url) VALUES (?1, ?2)", [code, url])
    Agent.update(__MODULE__, &Map.put(&1, code, url))
    code
  end

  def get(code) do
    case Repo.query("SELECT url FROM links WHERE code = ?1", [code]) do
      {:ok, %{rows: [[url]]}} -> url
      {:ok, _} -> nil
      {:error, _} -> nil
      _ -> Agent.get(__MODULE__, &Map.get(&1, code))
    end
  end

  def healthy?, do: match?({:ok, _}, Repo.query("SELECT 1"))

  defp generate_unique_code do
    Stream.repeatedly(&generate_code/0)
    |> Enum.find_value(fn code ->
      if is_nil(get(code)), do: code
    end)
  end

  defp generate_code do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
