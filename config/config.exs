import Config

config :shortener, start_server: config_env() != :test
