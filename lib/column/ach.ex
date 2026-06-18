defmodule Column.ACH do
  @moduledoc """
  ACH transfer origination and receipt.

  Supports CREDIT and DEBIT, standard and same-day settlement.
  Entry class codes: PPD, CCD, WEB, TEL, POP, IAT.

  ## Creating a credit

      {:ok, transfer} = Column.ACH.create(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        amount: 10_000,          # in cents
        currency_code: "USD",
        type: "CREDIT",
        entry_class_code: "PPD",
        company_entry_description: "PAYROLL",
        effective_date: "2024-06-15"
      })

  ## Same-day ACH

      Column.ACH.create(%{..., same_day: true})

  ## Returns

  Use `create_return/2` when you receive an inbound ACH you need to reject
  (e.g. account frozen). `reverse/2` is for reversing an ACH you originated
  within 5 business days.
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create an ACH transfer (CREDIT or DEBIT)."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/transfers/ach", params, opts)
  end

  @doc "List all ACH transfers. Supports cursor pagination and optional filters."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [
      :limit,
      :starting_after,
      :ending_before,
      :bank_account_id,
      :counterparty_id,
      :type,
      :status
    ]

    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/transfers/ach", Keyword.put(opts, :params, params))
  end

  @doc "Get an ACH transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/ach/#{id}", opts)
  end

  @doc "Cancel an ACH transfer (only possible before it has been submitted to the network)."
  @spec cancel(id(), opts()) :: result()
  def cancel(id, opts \\ []) do
    Client.post("/transfers/ach/#{id}/cancel", nil, opts)
  end

  @doc """
  Reverse an ACH transfer you originated.
  Must be within 5 business days of settlement. Full amount only.
  """
  @spec reverse(id(), params(), opts()) :: result()
  def reverse(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/ach/#{id}/reverse", params, opts)
  end

  @doc "Create an ACH return for an inbound transfer."
  @spec create_return(id(), params(), opts()) :: result()
  def create_return(id, params, opts \\ []) do
    Client.post("/transfers/ach/#{id}/returns", params, opts)
  end

  @doc "List all ACH returns for a transfer."
  @spec list_returns(id(), opts()) :: result()
  def list_returns(id, opts \\ []) do
    Client.get("/transfers/ach/#{id}/returns", opts)
  end

  @doc "Get a specific ACH return."
  @spec get_return(String.t(), opts()) :: result()
  def get_return(return_id, opts \\ []) do
    Client.get("/transfers/ach/returns/#{return_id}", opts)
  end

  # ---------------------------------------------------------------------------
  # Positive Pay Rules
  # ---------------------------------------------------------------------------

  @doc "Create an ACH positive pay rule to block unauthorized debits."
  @spec create_positive_pay_rule(params(), opts()) :: result()
  def create_positive_pay_rule(params, opts \\ []) do
    Client.post("/ach-positive-pay-rules", params, opts)
  end

  @doc "List ACH positive pay rules."
  @spec list_positive_pay_rules(opts()) :: result()
  def list_positive_pay_rules(opts \\ []) do
    Client.get("/ach-positive-pay-rules", opts)
  end

  @doc "Get an ACH positive pay rule."
  @spec get_positive_pay_rule(id(), opts()) :: result()
  def get_positive_pay_rule(id, opts \\ []) do
    Client.get("/ach-positive-pay-rules/#{id}", opts)
  end

  @doc "Delete an ACH positive pay rule."
  @spec delete_positive_pay_rule(id(), opts()) :: result()
  def delete_positive_pay_rule(id, opts \\ []) do
    Client.delete("/ach-positive-pay-rules/#{id}", opts)
  end
end
