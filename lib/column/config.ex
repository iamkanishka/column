defmodule Column.Config do
  @moduledoc """
  Runtime configuration for the Column API client.

  Configuration can be set globally via `config/config.exs`:

      config :column,
        api_key: System.get_env("COLUMN_API_KEY"),
        base_url: "https://api.column.com",
        timeout: 30_000,
        recv_timeout: 60_000,
        max_retries: 3,
        retry_delay: 500

  Or supplied per-request by passing a `Column.Config` struct in options:

      Column.BankAccounts.list(config: %Column.Config{api_key: "live_..."})
  """

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          base_url: String.t(),
          timeout: pos_integer(),
          recv_timeout: pos_integer(),
          max_retries: non_neg_integer(),
          retry_delay: pos_integer()
        }

  defstruct api_key: nil,
            base_url: "https://api.column.com",
            timeout: 30_000,
            recv_timeout: 60_000,
            max_retries: 3,
            retry_delay: 500

  @doc "Returns the effective config, merging application env with defaults."
  @spec new(keyword()) :: t()
  def new(overrides \\ []) do
    env = Application.get_all_env(:column)

    %__MODULE__{
      api_key: Keyword.get(overrides, :api_key, env[:api_key]),
      base_url: Keyword.get(overrides, :base_url, env[:base_url] || "https://api.column.com"),
      timeout: Keyword.get(overrides, :timeout, env[:timeout] || 30_000),
      recv_timeout: Keyword.get(overrides, :recv_timeout, env[:recv_timeout] || 60_000),
      max_retries: Keyword.get(overrides, :max_retries, env[:max_retries] || 3),
      retry_delay: Keyword.get(overrides, :retry_delay, env[:retry_delay] || 500)
    }
  end

  @doc "Validates that the config has the minimum required fields."
  @spec validate!(t()) :: t() | no_return()
  def validate!(%__MODULE__{api_key: nil}),
    do: raise(ArgumentError, "Column API key is required. Set :api_key in config or pass it directly.")

  def validate!(%__MODULE__{api_key: ""}),
    do: raise(ArgumentError, "Column API key must not be empty.")

  def validate!(%__MODULE__{} = config), do: config
end
