defmodule Shortener.Router do
  use Plug.Router
  use Plug.ErrorHandler

  @max_url_bytes 2048

  plug(Plug.Logger)
  plug(:security_headers)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded], length: 8_192)
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
    case valid_code?(code) && Shortener.Store.get(code) do
      url when is_binary(url) -> conn |> put_resp_header("location", url) |> send_resp(302, "")
      _ -> send_resp(conn, 404, "not found\n")
    end
  end

  match _ do
    send_resp(conn, 404, "not found\n")
  end

  def handle_errors(conn, %{reason: reason}) do
    conn
    |> security_headers([])
    |> send_resp(Plug.Exception.status(reason), "error\n")
  end

  defp security_headers(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-frame-options", "DENY")
    |> put_resp_header("referrer-policy", "no-referrer")
    |> put_resp_header("content-security-policy", "default-src 'none'; frame-ancestors 'none'")
    |> put_resp_header("permissions-policy", "geolocation=(), camera=(), microphone=()")
    |> put_resp_header("cache-control", "no-store")
  end

  # Codes are 5 random bytes, base64url-encoded: always 7 characters.
  defp valid_code?(code), do: String.match?(code, ~r/\A[A-Za-z0-9_-]{7}\z/)

  defp valid_url?(url) when is_binary(url) and byte_size(url) <= @max_url_bytes do
    # Reject whitespace and control characters (blocks CR/LF header injection).
    if String.match?(url, ~r/[\x00-\x20\x7f]/) do
      false
    else
      case URI.parse(url) do
        %URI{scheme: s, host: h, userinfo: nil}
        when s in ["http", "https"] and is_binary(h) and h != "" ->
          true

        _ ->
          false
      end
    end
  end

  defp valid_url?(_), do: false
end
