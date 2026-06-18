import Config

# Default config. Override in config/runtime.exs using System.get_env/1
config :column,
  api_key: nil,
  base_url: "https://api.column.com",
  timeout: 30_000,
  recv_timeout: 60_000,
  max_retries: 3,
  retry_delay: 500
