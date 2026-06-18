defmodule Column do
  @moduledoc """
  Production-grade Elixir client for the [Column Bank API](https://docs.column.com).

  Column is a bank-as-a-service platform providing FDIC-insured accounts,
  KYC/KYB compliance, and every major US payment rail: ACH, Fedwire,
  SWIFT international wires, RTP/FedNow realtime payments, and checks.

  ## Installation

  Add `column` to your dependencies in `mix.exs`:

      def deps do
        [
          {:column, "~> 0.1"}
        ]
      end

  ## Configuration

  Set your Column API key in `config/config.exs`:

      config :column, api_key: System.get_env("COLUMN_API_KEY")

  For runtime configuration (e.g. `config/runtime.exs`):

      config :column,
        api_key: System.get_env("COLUMN_API_KEY"),
        base_url: "https://api.column.com",  # default
        timeout: 30_000,
        max_retries: 3

  Per-request config override (useful for multi-tenant setups):

      config = %Column.Config{api_key: "live_abc123"}
      Column.BankAccounts.list(config: config)

  ## Environments

  - **Sandbox:** Use `test_...` prefixed API keys. Call `Column.Simulation.*`
    to trigger synthetic network events.
  - **Production:** Use `live_...` prefixed API keys.

  ## Module map

  | Domain | Module |
  |---|---|
  | KYC / KYB | `Column.Entities` |
  | Bank accounts | `Column.BankAccounts` |
  | Virtual account numbers | `Column.AccountNumbers` |
  | Counterparties | `Column.Counterparties` |
  | ACH transfers + positive pay | `Column.ACH` |
  | Book transfers | `Column.BookTransfers` |
  | Domestic wires | `Column.Wires` |
  | International wires + FX | `Column.InternationalWires` |
  | Realtime (RTP / FedNow) | `Column.RealtimeTransfers` |
  | Checks | `Column.Checks` |
  | All transfers unified | `Column.Transfers` |
  | Loans & programs | `Column.Loans` |
  | Loan disbursements | `Column.Disbursements` |
  | Loan payments | `Column.LoanPayments` |
  | Events | `Column.Events` |
  | Webhooks | `Column.Webhooks` |
  | Reporting | `Column.Reporting` |
  | Documents | `Column.Documents` |
  | Sandbox simulation | `Column.Simulation` |
  | Pagination helpers | `Column.Pagination` |
  | HTTP client | `Column.Client` |
  | Config | `Column.Config` |
  | Error type | `Column.Error` |

  ## Error handling

  All functions return `{:ok, map()}` or `{:error, %Column.Error{}}`:

      case Column.BankAccounts.get("bacc_missing") do
        {:ok, account} ->
          account
        {:error, %Column.Error{type: :api_error, status: 404}} ->
          {:error, :not_found}
        {:error, %Column.Error{type: :network_error} = err} ->
          Logger.error("Column network error: \#{err.message}")
          {:error, :unavailable}
      end

  ## Pagination

  All list functions support cursor pagination. Use `Column.Pagination.stream/2`
  to consume pages lazily as a `Stream`:

      Column.Pagination.stream(&Column.Transfers.list/1, limit: 100)
      |> Stream.filter(fn transfer -> transfer["status"] == "SETTLED" end)
      |> Enum.to_list()

  ## Idempotency

  All POST requests automatically generate and attach an `Idempotency-Key`
  header. Supply your own to control retry behaviour:

      Column.ACH.create(%{...}, idempotency_key: "my-unique-key")

  ## Webhook signature verification

      Column.Webhooks.verify_signature(raw_body, signature_header, webhook_secret)
      # => :ok | :error
  """

  @doc """
  Returns the current library version.

  ## Module map

  | Domain | Module |
  |---|---|
  | KYC / KYB | `Column.Entities` |
  | Bank accounts | `Column.BankAccounts` |
  | Virtual account numbers | `Column.AccountNumbers` |
  | Counterparties | `Column.Counterparties` |
  | ACH transfers + positive pay | `Column.ACH` |
  | Book transfers | `Column.BookTransfers` |
  | Domestic wires | `Column.Wires` |
  | International wires + FX | `Column.InternationalWires` |
  | Realtime (RTP / FedNow) | `Column.RealtimeTransfers` |
  | Checks | `Column.Checks` |
  | All transfers unified | `Column.Transfers` |
  | Loans & programs | `Column.Loans` |
  | Loan disbursements | `Column.Disbursements` |
  | Loan payments | `Column.LoanPayments` |
  | Events | `Column.Events` |
  | Webhooks | `Column.Webhooks` |
  | Webhook handler behaviour | `Column.WebhookHandler` |
  | Reporting | `Column.Reporting` |
  | Documents | `Column.Documents` |
  | Sandbox simulation | `Column.Simulation` |
  | Pagination helpers | `Column.Pagination` |
  | Money / currency helpers | `Column.Money` |
  | Param builder / validation | `Column.Params` |
  | Idempotency key helpers | `Column.Idempotency` |
  | Rate limit parsing | `Column.RateLimit` |
  | Telemetry events | `Column.Telemetry` |
  | HTTP client | `Column.Client` |
  | Config | `Column.Config` |
  | Error type | `Column.Error` |
  """
  @spec version() :: String.t()
  def version, do: to_string(Application.spec(:column, :vsn))
end
