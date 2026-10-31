# Shortener

A minimal URL shortener built with Elixir, Plug and Bandit. Links are kept
in memory, so they are lost on restart.

## Requirements

- Elixir 1.20+ and Erlang/OTP 28+

## Run

```bash
mix deps.get
mix run --no-halt
```

The server listens on port 4000. Set `PORT` to change it.

## Usage

Shorten a URL:

```bash
curl --data-urlencode "url=https://elixir-lang.org" localhost:4000
# http://localhost:4000/AbC123x
```

Follow it:

```bash
curl -i localhost:4000/AbC123x
# HTTP/1.1 302 ... location: https://elixir-lang.org
```

Use `--data-urlencode` so `&` and `+` in long URLs survive. On Windows
PowerShell, use `curl.exe` instead of `curl`.

| Method | Path     | Result                                        |
|--------|----------|-----------------------------------------------|
| POST   | `/`      | `201` with short URL, or `400` if invalid     |
| GET    | `/:code` | `302` redirect, or `404` if the code is unknown |

Only `http` and `https` URLs are accepted. The destination is not checked
for reachability.

## Test

```bash
mix test
```

## Docker

```bash
docker build -t shortener .
docker run -p 4000:4000 shortener
```

## CI/CD

GitHub Actions checks formatting, compiles with warnings as errors and runs
the tests on every push and pull request. Pushes to `main` also publish an
image to `ghcr.io/<owner>/<repo>`.

## Limitations

- In-memory storage (Agent), no persistence
- No rate limiting
- The returned short URL is built from the request host and port, so behind
  a reverse proxy it needs a configurable base URL