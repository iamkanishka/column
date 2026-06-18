# Column

Production-grade Elixir client for the [Column Bank API](https://docs.column.com).

Column is a bank-as-a-service platform providing FDIC-insured accounts, KYC/KYB compliance,
and every major US payment rail: ACH, Fedwire, SWIFT international wires, RTP/FedNow realtime
payments, and checks — plus a full lending API.

## Installation

```elixir
def deps do
  [
    {:column, "~> 1.0"}
  ]
end
```

## Configuration

```elixir
# config/runtime.exs
config :column,
  api_key: System.fetch_env!("COLUMN_API_KEY"),
  base_url: "https://api.column.com",   # default
  timeout: 30_000,                       # ms
  recv_timeout: 60_000,                  # ms
  max_retries: 3,
  retry_delay: 500                       # ms, doubles each retry
```

## Quick start

```elixir
# Create an entity (KYC)
{:ok, person} = Column.Entities.create_person(%{
  first_name: "Ada",
  last_name: "Lovelace",
  email: "ada@example.com",
  date_of_birth: "1815-12-10",
  ssn: "123-45-6789",
  address: %{line_1: "123 Main St", city: "San Francisco", state: "CA",
             postal_code: "94102", country_code: "US"}
})

# Open a bank account
{:ok, account} = Column.BankAccounts.create(%{
  description: "Ada's wallet",
  entity_id: person["id"]
})

# Send an ACH credit
{:ok, transfer} = Column.ACH.create(%{
  bank_account_id: account["id"],
  counterparty_id: "cpty_456",
  amount: 100_00,         # in cents
  currency_code: "USD",
  type: "CREDIT",
  entry_class_code: "PPD",
  company_entry_description: "PAYROLL"
})

# Realtime transfer (RTP/FedNow) — settles in seconds
{:ok, rt} = Column.RealtimeTransfers.create(%{
  bank_account_id: account["id"],
  counterparty_id: "cpty_456",
  amount: 5_000,
  currency_code: "USD"
})

# International wire with FX quote
{:ok, quote} = Column.InternationalWires.request_fx_quote(%{
  buy_currency: "EUR", sell_currency: "USD", buy_amount: 10_000
})
{:ok, _} = Column.InternationalWires.book_fx_quote(quote["id"])
{:ok, wire} = Column.InternationalWires.create(%{
  bank_account_id: account["id"],
  fx_quote_id: quote["id"],
  beneficiary_iban: "DE89370400440532013000",
  beneficiary_name: "Acme GmbH"
})
```

## Feature coverage

| Feature | Module |
|---|---|
| KYC (persons) | `Column.Entities` |
| KYB (businesses) | `Column.Entities` |
| Documentary evidence & narratives | `Column.Entities` |
| Bank accounts (FBO, sweep, clearing) | `Column.BankAccounts` |
| Virtual account numbers | `Column.AccountNumbers` |
| Counterparties + IBAN validation | `Column.Counterparties` |
| ACH credits & debits (PPD/CCD/WEB/TEL/POP/IAT) | `Column.ACH` |
| ACH same-day, returns, reversals | `Column.ACH` |
| ACH positive pay rules | `Column.ACH` |
| Book transfers (instant, internal) | `Column.BookTransfers` |
| Domestic wires (Fedwire) | `Column.Wires` |
| Wire drawdown requests | `Column.Wires` |
| Wire return request flow | `Column.Wires` |
| International wires (SWIFT) | `Column.InternationalWires` |
| FX quotes + rate sheet | `Column.InternationalWires` |
| SWIFT gpi tracking | `Column.InternationalWires` |
| Realtime transfers (RTP + FedNow) | `Column.RealtimeTransfers` |
| Request for Payment (RFP) | `Column.RealtimeTransfers` |
| Realtime return requests | `Column.RealtimeTransfers` |
| Check issuance (print & mail) | `Column.Checks` |
| Remote deposit capture | `Column.Checks` |
| Unified transfer list | `Column.Transfers` |
| Loans & loan programs | `Column.Loans` |
| Loan disbursements (with hold) | `Column.Disbursements` |
| Loan payments & returns | `Column.LoanPayments` |
| Loan sales (secondary market) | `Column.Loans` |
| Events (audit log) | `Column.Events` |
| Webhooks + signature verification | `Column.Webhooks` |
| Settlement reports | `Column.Reporting` |
| Bank account statements | `Column.Reporting` |
| Document uploads | `Column.Documents` |
| Sandbox simulation | `Column.Simulation` |
| Cursor pagination + streaming | `Column.Pagination` |

## Pagination

All list endpoints support cursor-based pagination. Stream all pages lazily:

```elixir
Column.Pagination.stream(&Column.Transfers.list/1, limit: 100)
|> Stream.filter(fn t -> t["status"] == "SETTLED" end)
|> Enum.to_list()

# Or fetch everything at once
{:ok, all_accounts} = Column.Pagination.fetch_all(&Column.BankAccounts.list/1)
```

## Error handling

All functions return `{:ok, map()}` or `{:error, %Column.Error{}}`:

```elixir
case Column.BankAccounts.get("bacc_missing") do
  {:ok, account} ->
    account
  {:error, %Column.Error{type: :api_error, status: 404}} ->
    {:error, :not_found}
  {:error, %Column.Error{type: :network_error, message: msg}} ->
    Logger.error("Column network error: #{msg}")
    {:error, :unavailable}
  {:error, %Column.Error{type: :api_error, status: 429}} ->
    {:error, :rate_limited}
end
```

Error types: `:api_error`, `:network_error`, `:decode_error`, `:validation_error`.

## Idempotency

All POST requests automatically generate an `Idempotency-Key` header. Supply
your own key to control retry behaviour:

```elixir
Column.ACH.create(%{...}, idempotency_key: "payment-#{order_id}")
```

## Webhook signature verification

```elixir
def handle_webhook(conn) do
  sig = get_req_header(conn, "column-signature") |> List.first()
  raw_body = conn.assigns[:raw_body]
  secret = System.fetch_env!("COLUMN_WEBHOOK_SECRET")

  case Column.Webhooks.verify_signature(raw_body, sig, secret) do
    :ok    -> process_event(conn)
    :error -> send_resp(conn, 401, "Unauthorized")
  end
end
```

## Per-request config (multi-tenant)

Override config on any individual call:

```elixir
config = %Column.Config{api_key: tenant.column_api_key}
Column.BankAccounts.list(config: config)
```

## Retry behaviour

Transient HTTP errors (408, 429, 500, 502, 503, 504) are retried automatically
with exponential backoff + random jitter. Configure via `:max_retries` and
`:retry_delay` (in ms).

## Sandbox testing

```elixir
# Simulate receiving an inbound ACH credit
{:ok, _} = Column.Simulation.receive_ach_credit(%{
  bank_account_id: "bacc_sandbox",
  amount: 100_000,
  currency_code: "USD"
})

# Settle it
{:ok, transfers} = Column.ACH.list(bank_account_id: "bacc_sandbox")
Column.Simulation.settle_ach(hd(transfers["data"])["id"])
```

## License

MIT
