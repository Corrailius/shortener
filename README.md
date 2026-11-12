# Shortener

A lightweight URL shortener built with Elixir, Plug and Bandit.

## Features

- Professional HTML interface in the browser at `/`
- API-compatible POST endpoint for scripts and curl
- SQLite persistence with a migration file for permanent storage
- Security checks for malformed URLs and injection attempts
- Automated tests with Mix

## Requirements

- Elixir 1.20+
- Erlang/OTP 28+

## Run locally

```bash
mix deps.get
mix test
mix format
$env:PATH = "C:\elixir-install\otp\bin;C:\elixir-install\elixir\bin;$env:PATH"
mix run --no-halt
```

Then open:

- http://localhost:4000

The server listens on port `4000` by default. You can override it with:

```bash
PORT=5000 mix run --no-halt
```

## Usage

### Browser interface

Open the app in a browser and paste a URL into the form.

### CLI/API

```bash
curl.exe --data-urlencode "url=https://elixir-lang.org" http://localhost:4000
# http://localhost:4000/AbC123x
```

Follow the redirect:

```bash
curl.exe -I http://localhost:4000/AbC123x
```

| Method | Path     | Result                                        |
|--------|----------|-----------------------------------------------|
| GET    | `/`      | Professional page with a form                 |
| POST   | `/`      | `201` with short URL, or `400` if invalid     |
| GET    | `/:code` | `302` redirect, or `404` if the code is unknown |

Only `http` and `https` URLs are accepted. The destination is not checked
for reachability.

## Persistence

The application stores short links in SQLite through an Ecto migration in:

- `priv/repo/migrations/`

The database file is stored locally as `shortener_dev.db` by default and is kept
between restarts.

## Test

```bash
mix test
mix format
```

## Docker

```bash
docker build -t shortener .
docker run -p 4000:4000 shortener
```

## CI/CD

GitHub Actions can validate formatting and run the automated test suite on each
push and pull request.
