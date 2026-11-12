defmodule Shortener.Router do
  use Plug.Router
  use Plug.ErrorHandler

  @max_url_bytes 2048

  plug(Plug.Logger)
  plug(:security_headers)
  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded], length: 8_192)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, home_page())
  end

  post "/" do
    url = conn.body_params["url"]

    if valid_url?(url) do
      code = Shortener.Store.put(url)
      short_url = build_short_url(conn, code)

      if browser_request?(conn) do
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(201, home_page(short_url: short_url, value: url))
      else
        send_resp(conn, 201, "#{short_url}\n")
      end
    else
      if browser_request?(conn) do
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(400, home_page(error: "provide a valid http(s) url", value: url))
      else
        send_resp(conn, 400, "provide a valid http(s) url\n")
      end
    end
  end

  get "/:code" do
    case valid_code?(code) && Shortener.Store.get(code) do
      url when is_binary(url) -> conn |> put_resp_header("location", url) |> send_resp(302, "")
      _ -> send_resp(conn, 404, "not found\n")
    end
  end

  get "/forward/:code" do
    handle_forward(conn, code)
  end

  get "/f/:code" do
    handle_forward(conn, code)
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

  defp browser_request?(conn) do
    conn
    |> get_req_header("accept")
    |> List.first("")
    |> Kernel.to_string()
    |> String.contains?("text/html")
  end

  defp build_short_url(conn, code) do
    "#{conn.scheme}://#{conn.host}:#{conn.port}/#{code}"
  end

  defp handle_forward(conn, code) do
    case valid_code?(code) && Shortener.Store.get(code) do
      url when is_binary(url) ->
        case fetch_forward(url) do
          {:ok, {status, headers, body}} ->
            conn
            |> apply_forward_headers(headers)
            |> send_resp(status, body)

          {:error, _reason} ->
            send_resp(conn, 502, "forward failed\n")
        end

      _ ->
        send_resp(conn, 404, "not found\n")
    end
  end

  defp fetch_forward(url) do
    case Finch.request(Finch.build(:get, url), Shortener.Finch) do
      {:ok, %Finch.Response{status: status, headers: headers, body: body}} ->
        {:ok, {status, headers, body}}

      {:error, _} = error ->
        error
    end
  end

  defp apply_forward_headers(conn, headers) do
    Enum.reduce(headers, conn, fn
      {name, value}, acc ->
        header_name = to_string(name)

        if String.downcase(header_name) in [
             "content-length",
             "transfer-encoding",
             "connection",
             "keep-alive",
             "proxy-connection"
           ] do
          acc
        else
          put_resp_header(acc, header_name, to_string(value))
        end
    end)
  end

  defp home_page(opts \\ []) do
    short_url = Keyword.get(opts, :short_url)
    error = Keyword.get(opts, :error)
    value = Keyword.get(opts, :value, "")

    short_block =
      if short_url do
        safe_url = Plug.HTML.html_escape(short_url) |> to_string()

        """
        <div class="card success">
          <h2>Votre lien raccourci</h2>
          <p><a href=\"#{safe_url}\" target=\"_blank\" rel=\"noreferrer\">#{safe_url}</a></p>
        </div>
        """
      else
        ""
      end

    error_block =
      if error do
        safe_error = Plug.HTML.html_escape(error) |> to_string()

        """
        <div class="alert error">#{safe_error}</div>
        """
      else
        ""
      end

    safe_value = Plug.HTML.html_escape(value) |> to_string()

    """
    <!DOCTYPE html>
    <html lang=\"fr\">
      <head>
        <meta charset=\"utf-8\" />
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
        <title>YBoost Shortener</title>
        <style>
          :root {
            --bg: #f3f6fb;
            --panel: #ffffff;
            --primary: #1d4ed8;
            --primary-dark: #1e3a8a;
            --text: #0f172a;
            --muted: #475569;
            --border: #dbe3f0;
            --error: #b91c1c;
            --success: #166534;
          }

          * { box-sizing: border-box; }
          body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(135deg, #eff6ff 0%, #f8fafc 100%);
            color: var(--text);
          }

          .wrap {
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 2rem;
          }

          .panel {
            width: min(720px, 100%);
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 20px;
            box-shadow: 0 18px 45px rgba(15, 23, 42, 0.08);
            padding: 2rem;
          }

          h1 {
            margin: 0;
            font-size: clamp(2rem, 3vw, 2.8rem);
          }

          .subtitle {
            margin: 0.75rem 0 1.5rem;
            color: var(--muted);
            line-height: 1.6;
          }

          form {
            display: grid;
            gap: 1rem;
            margin-top: 1rem;
          }

          label {
            display: block;
            font-weight: 700;
            margin-bottom: 0.4rem;
          }

          input {
            width: 100%;
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 0.9rem 1rem;
            font-size: 1rem;
            background: #fff;
          }

          button {
            border: none;
            border-radius: 12px;
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: #fff;
            font-weight: 700;
            font-size: 1rem;
            padding: 0.9rem 1.2rem;
            cursor: pointer;
          }

          .card {
            margin-top: 1.5rem;
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1rem 1.1rem;
            background: #f8fafc;
          }

          .success { border-color: #bbf7d0; background: #f0fdf4; }
          .error { border-color: #fecaca; background: #fef2f2; color: var(--error); }
          .alert { margin-top: 1rem; padding: 0.8rem 1rem; border-radius: 12px; }
        </style>
      </head>
      <body>
        <div class="wrap">
          <main class="panel">
            <h1>YBoost Shortener</h1>
            <p class="subtitle">Créez des liens courts et fiables, sans dépendre d’un outil en ligne de commande.</p>

            <form action="/" method="post">
              <div>
                <label for="url">URL à raccourcir</label>
                <input id="url" name="url" type="url" value="#{safe_value}" placeholder="https://example.com" required />
              </div>
              <button type="submit">Raccourcir le lien</button>
            </form>

            #{error_block}
            #{short_block}
          </main>
        </div>
      </body>
    </html>
    """
  end

  # Codes are 5 random bytes, base64url-encoded: always 7 characters.
  defp valid_code?(code), do: String.match?(code, ~r/\A[A-Za-z0-9_-]{7}\z/)

  defp valid_url?(url) when is_binary(url) and byte_size(url) <= @max_url_bytes do
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
