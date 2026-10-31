defmodule Shortener.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded])
  plug(:dispatch)

  post "/" do
    url = conn.body_params["url"]

    if valid_url?(url) do
      code = Shortener.Store.put(url)
      send_resp(conn, 201, "#{conn.scheme}://#{conn.host}:#{conn.port}/#{code}\n")
    else
      send_resp(conn, 400, "provide a valid http(s) url\n")
    end
  end

  get "/:code" do
    case Shortener.Store.get(code) do
      nil -> send_resp(conn, 404, "not found\n")
      url -> conn |> put_resp_header("location", url) |> send_resp(302, "")
    end
  end

  match _ do
    send_resp(conn, 404, "not found\n")
  end

  defp valid_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: s, host: h} when s in ["http", "https"] and is_binary(h) -> true
      _ -> false
    end
  end

  defp valid_url?(_), do: false
end
