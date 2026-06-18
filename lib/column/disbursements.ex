defmodule Column.Disbursements do
  @moduledoc """
  Loan disbursements with optional two-phase hold.

  Disbursements move funds from a loan into a bank account.
  The hold pattern lets you reserve funds and then clear or cancel later,
  identical to the book transfer hold pattern.

  ## Immediate disbursement

      {:ok, disb} = Column.Disbursements.create(%{
        loan_id: "loan_123",
        bank_account_id: "bacc_456",
        amount: 500_000,
        currency_code: "USD"
      })

  ## Held disbursement

      {:ok, disb} = Column.Disbursements.create(%{
        loan_id: "loan_123",
        bank_account_id: "bacc_456",
        amount: 500_000,
        currency_code: "USD",
        hold: true
      })

      Column.Disbursements.clear(disb["id"])
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a loan disbursement."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/loans/disbursements", params, opts)
  end

  @doc "List all disbursements."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [:limit, :starting_after, :ending_before, :loan_id, :bank_account_id]
    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/loans/disbursements", Keyword.put(opts, :params, params))
  end

  @doc "Get a disbursement by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/loans/disbursements/#{id}", opts)
  end

  @doc "Update a disbursement while it is on hold."
  @spec update(id(), params(), opts()) :: result()
  def update(id, params, opts \\ []) do
    Client.patch("/loans/disbursements/#{id}", params, opts)
  end

  @doc "Cancel a held disbursement."
  @spec cancel(id(), opts()) :: result()
  def cancel(id, opts \\ []) do
    Client.post("/loans/disbursements/#{id}/cancel", nil, opts)
  end

  @doc "Clear (execute) a held disbursement."
  @spec clear(id(), opts()) :: result()
  def clear(id, opts \\ []) do
    Client.post("/loans/disbursements/#{id}/clear", nil, opts)
  end
end
