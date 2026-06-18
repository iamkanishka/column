defmodule Column.InternationalWires do
  @moduledoc """
  Cross-border SWIFT wire transfers in 100+ currencies.

  ## FX quote lifecycle

  When sending in a foreign currency, you must first obtain and book an FX quote:

      # 1. Request a quote
      {:ok, quote} = Column.InternationalWires.request_fx_quote(%{
        buy_currency: "EUR",
        sell_currency: "USD",
        buy_amount: 10_000
      })

      # 2. Book the quote (locks the rate)
      {:ok, booked} = Column.InternationalWires.book_fx_quote(quote["id"])

      # 3. Create the transfer referencing the booked quote
      {:ok, wire} = Column.InternationalWires.create(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        fx_quote_id: booked["id"],
        beneficiary_name: "Acme GmbH",
        beneficiary_iban: "DE89370400440532013000",
        beneficiary_address: %{...}
      })

  ## Tracking

  Use `track/2` to get SWIFT gpi status updates on outgoing transfers.
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  # ---------------------------------------------------------------------------
  # Transfers
  # ---------------------------------------------------------------------------

  @doc "Create an international wire transfer."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/transfers/international-wire", params, opts)
  end

  @doc "List all international wire transfers."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before, :bank_account_id]), %{})
    Client.get("/transfers/international-wire", Keyword.put(opts, :params, params))
  end

  @doc "Get an international wire transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/international-wire/#{id}", opts)
  end

  @doc "Track an international wire transfer via SWIFT gpi."
  @spec track(id(), opts()) :: result()
  def track(id, opts \\ []) do
    Client.get("/transfers/international-wire/#{id}/tracking", opts)
  end

  @doc "Return an incoming international wire."
  @spec return_incoming(id(), params(), opts()) :: result()
  def return_incoming(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/international-wire/#{id}/return", params, opts)
  end

  @doc "Cancel an outgoing international wire."
  @spec cancel(id(), params(), opts()) :: result()
  def cancel(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/international-wire/#{id}/cancel", params, opts)
  end

  @doc "Submit an amendment to an international wire."
  @spec create_amendment(id(), params(), opts()) :: result()
  def create_amendment(id, params, opts \\ []) do
    Client.post("/transfers/international-wire/#{id}/amendment", params, opts)
  end

  # ---------------------------------------------------------------------------
  # FX Rate Sheet
  # ---------------------------------------------------------------------------

  @doc "Get the current FX rate sheet."
  @spec get_fx_rate_sheet(opts()) :: result()
  def get_fx_rate_sheet(opts \\ []) do
    Client.get("/transfers/international-wire/fx-rate-sheet", opts)
  end

  # ---------------------------------------------------------------------------
  # FX Quotes
  # ---------------------------------------------------------------------------

  @doc "Request a foreign exchange quote."
  @spec request_fx_quote(params(), opts()) :: result()
  def request_fx_quote(params, opts \\ []) do
    Client.post("/transfers/international-wire/fx-quotes", params, opts)
  end

  @doc "Get a foreign exchange quote by ID."
  @spec get_fx_quote(id(), opts()) :: result()
  def get_fx_quote(id, opts \\ []) do
    Client.get("/transfers/international-wire/fx-quotes/#{id}", opts)
  end

  @doc "Book (lock) a foreign exchange quote."
  @spec book_fx_quote(id(), opts()) :: result()
  def book_fx_quote(id, opts \\ []) do
    Client.post("/transfers/international-wire/fx-quotes/#{id}/book", nil, opts)
  end

  @doc "Cancel a foreign exchange quote."
  @spec cancel_fx_quote(id(), opts()) :: result()
  def cancel_fx_quote(id, opts \\ []) do
    Client.post("/transfers/international-wire/fx-quotes/#{id}/cancel", nil, opts)
  end
end
