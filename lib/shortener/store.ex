defmodule Shortener.Store do
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def put(url) do
    code = generate_code()
    Agent.update(__MODULE__, &Map.put(&1, code, url))
    code
  end

  def get(code), do: Agent.get(__MODULE__, &Map.get(&1, code))

  defp generate_code do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
