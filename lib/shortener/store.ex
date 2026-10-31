defmodule Shortener.Store do
  alias Shortener.Repo

  def setup do
    Repo.query!("CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT NOT NULL)")
  end

  def put(url) do
    code = generate_code()
    Repo.query!("INSERT INTO links (code, url) VALUES (?1, ?2)", [code, url])
    code
  end

  def get(code) do
    case Repo.query!("SELECT url FROM links WHERE code = ?1", [code]) do
      %{rows: [[url]]} -> url
      _ -> nil
    end
  end

  def healthy?, do: match?({:ok, _}, Repo.query("SELECT 1"))

  defp generate_code do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
