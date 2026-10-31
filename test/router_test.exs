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
end
