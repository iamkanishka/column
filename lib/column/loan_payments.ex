defmodule Column.LoanPayments do
  @moduledoc """
  Loan payment collection and return handling.

  ## Creating a payment

      {:ok, payment} = Column.LoanPayments.create(%{
        loan_id: "loan_123",
        bank_account_id: "bacc_456",
        amount: 15_000,
        currency_code: "USD"
      })

  ## Returning a failed payment

      {:ok, _} = Column.LoanPayments.return(payment["id"], %{
        return_reason: "R01"
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a loan payment."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/loans/payments", params, opts)
  end

  @doc "List all loan payments."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [:limit, :starting_after, :ending_before, :loan_id, :bank_account_id, :status]
    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/loans/payments", Keyword.put(opts, :params, params))
  end

  @doc "Get a loan payment by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/loans/payments/#{id}", opts)
  end

  @doc "Return a loan payment."
  @spec return(id(), params(), opts()) :: result()
  def return(id, params \\ %{}, opts \\ []) do
    Client.post("/loans/payments/#{id}/return", params, opts)
  end
end
