defmodule Column.BookTransfers do
  @moduledoc """
  Instant, free internal transfers between two Column bank accounts.

  Book transfers are pure ledger movements — no external network involved.
  They support a two-phase hold pattern:

      1. `create/2` with `hold: true` — funds reserved but not moved
      2. `update/3` — optionally change amount/description while on hold
      3. `clear/2` — execute the held transfer
         OR `cancel/2` — abandon the hold

  ## Immediate transfer (no hold)

      {:ok, transfer} = Column.BookTransfers.create(%{
        sender_bank_account_id: "bacc_aaa",
        receiver_bank_account_id: "bacc_bbb",
        amount: 5_000,
        currency_code: "USD",
        description: "Settlement"
      })

  ## Two-phase hold

      {:ok, hold} = Column.BookTransfers.create(%{
        sender_bank_account_id: "bacc_aaa",
        receiver_bank_account_id: "bacc_bbb",
        amount: 5_000,
        currency_code: "USD",
        hold: true
      })

      # ... later, after authorization ...
      {:ok, _} = Column.BookTransfers.clear(hold["id"])
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a book transfer."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/transfers/book", params, opts)
  end

  @doc "List all book transfers. Supports cursor pagination."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before, :bank_account_id]), %{})
    Client.get("/transfers/book", Keyword.put(opts, :params, params))
  end

  @doc "Get a book transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/book/#{id}", opts)
  end

  @doc "Update a book transfer while it is on hold."
  @spec update(id(), params(), opts()) :: result()
  def update(id, params, opts \\ []) do
    Client.patch("/transfers/book/#{id}", params, opts)
  end

  @doc "Cancel a book transfer."
  @spec cancel(id(), opts()) :: result()
  def cancel(id, opts \\ []) do
    Client.post("/transfers/book/#{id}/cancel", nil, opts)
  end

  @doc "Clear (execute) a held book transfer."
  @spec clear(id(), opts()) :: result()
  def clear(id, opts \\ []) do
    Client.post("/transfers/book/#{id}/clear", nil, opts)
  end
end
