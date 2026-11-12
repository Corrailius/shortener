import Config

config :shortener,
  ecto_repos: [Shortener.Repo],
  start_server: config_env() != :test,
  db_path: "shortener_#{config_env()}.db"

config :shortener, Shortener.Repo,
  log: false,
  database: "shortener_#{config_env()}.db",
  pool_size: 5

if config_env() == :test do
  config :logger, level: :warning
end
