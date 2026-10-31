import Config

config :shortener,
  start_server: config_env() != :test,
  db_path: "shortener_#{config_env()}.db"

config :shortener, Shortener.Repo, log: false

if config_env() == :test do
  config :logger, level: :warning
end
