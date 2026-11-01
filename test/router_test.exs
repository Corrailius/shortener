defmodule Shortener.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  @opts Shortener.Router.init([])

  defp post_url(url) do
    conn(:post, "/", "url=" <> URI.encode_www_form(url))
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Shortener.Router.call(@opts)
  end

  test "shortens a URL and redirects to it" do
    url = "https://www.youtube.com/watch?v=abc&t=10s&list=PL1"
    conn = post_url(url)
    assert conn.status == 201

    code = conn.resp_body |> String.trim() |> String.split("/") |> List.last()
    conn = conn(:get, "/#{code}") |> Shortener.Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == [url]
  end

  test "rejects invalid and dangerous URLs" do
    for bad <- ["notaurl", "ftp://example.com/f", "javascript:alert(1)", ""] do
      assert post_url(bad).status == 400
    end
  end

  test "unknown code returns 404" do
    conn = conn(:get, "/nope") |> Shortener.Router.call(@opts)
    assert conn.status == 404
  end

  test "rejects URLs longer than 2048 bytes" do
    too_long = "https://example.com/?q=" <> String.duplicate("a", 2048)
    assert post_url(too_long).status == 400

    ok = "https://example.com/?q=" <> String.duplicate("a", 2000)
    assert post_url(ok).status == 201
  end

  test "rejects header injection, whitespace and credentials" do
    for bad <- [
          "https://example.com/a\r\nSet-Cookie: x=1",
          "https://example.com/a b",
          "https://user:pass@example.com/"
        ] do
      assert post_url(bad).status == 400
    end
  end

  test "SQL injection payloads are stored as data, never executed" do
    evil = "https://example.com/?q='%20OR%201=1;DROP%20TABLE%20links;--"
    conn = post_url(evil)
    assert conn.status == 201

    code = conn.resp_body |> String.trim() |> String.split("/") |> List.last()
    conn = conn(:get, "/#{code}") |> Shortener.Router.call(@opts)
    assert get_resp_header(conn, "location") == [evil]

    conn = conn(:get, "/%27%20OR%201=1--") |> Shortener.Router.call(@opts)
    assert conn.status == 404
  end

  test "responses carry security headers" do
    conn = conn(:get, "/nope") |> Shortener.Router.call(@opts)
    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
    assert ["text/plain" <> _] = get_resp_header(conn, "content-type")
  end
end
