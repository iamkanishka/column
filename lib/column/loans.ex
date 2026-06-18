defmodule Column.Loans do
  @moduledoc """
  Loan origination and lifecycle management.

  Loans are originated against a loan program. Funds are disbursed to a
  bank account (optionally with a hold), collected via payments, and can
  be sold to the secondary market.

  ## Full lifecycle example

      # 1. Check available loan programs
      {:ok, programs} = Column.Loans.list_programs()

      # 2. Originate a loan
      {:ok, loan} = Column.Loans.create(%{
        loan_program_id: "lpgm_123",
        bank_account_id: "bacc_456",
        amount: 500_000,
        currency_code: "USD",
        description: "Working capital"
      })

      # 3. Disburse funds (see Column.Disbursements)
      # 4. Accept payments (see Column.LoanPayments)
      # 5. Optionally sell the loan
      {:ok, sale} = Column.Loans.create_sale(loan["id"], %{
        buyer_entity_id: "ent_789"
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  # ---------------------------------------------------------------------------
  # Loans
  # ---------------------------------------------------------------------------

  @doc "Create a new loan."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/loans", params, opts)
  end

  @doc "List all loans. Supports cursor pagination."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [:limit, :starting_after, :ending_before, :bank_account_id, :status]
    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/loans", Keyword.put(opts, :params, params))
  end

  @doc "Get a loan by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/loans/#{id}", opts)
  end

  @doc "Update a loan."
  @spec update(id(), params(), opts()) :: result()
  def update(id, params, opts \\ []) do
    Client.patch("/loans/#{id}", params, opts)
  end

  @doc "Get loan summary history (balance snapshots)."
  @spec get_summary(id(), opts()) :: result()
  def get_summary(id, opts \\ []) do
    Client.get("/loans/#{id}/summary", opts)
  end

  # ---------------------------------------------------------------------------
  # Loan Programs
  # ---------------------------------------------------------------------------

  @doc "List available loan programs."
  @spec list_programs(opts()) :: result()
  def list_programs(opts \\ []) do
    Client.get("/loans/programs", opts)
  end

  @doc "Get a loan program by ID."
  @spec get_program(id(), opts()) :: result()
  def get_program(id, opts \\ []) do
    Client.get("/loans/programs/#{id}", opts)
  end

  @doc "Update a loan program."
  @spec update_program(id(), params(), opts()) :: result()
  def update_program(id, params, opts \\ []) do
    Client.patch("/loans/programs/#{id}", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Loan sales
  # ---------------------------------------------------------------------------

  @doc "Create a loan sale to the secondary market."
  @spec create_sale(id(), params(), opts()) :: result()
  def create_sale(id, params, opts \\ []) do
    Client.post("/loans/#{id}/sales", params, opts)
  end

  @doc "List all loan sales."
  @spec list_sales(opts()) :: result()
  def list_sales(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/loans/sales", Keyword.put(opts, :params, params))
  end

  @doc "Get a loan sale by ID."
  @spec get_sale(id(), opts()) :: result()
  def get_sale(id, opts \\ []) do
    Client.get("/loans/sales/#{id}", opts)
  end

  @doc "Get summaries for loans available for sale."
  @spec get_available_for_sale_summaries(opts()) :: result()
  def get_available_for_sale_summaries(opts \\ []) do
    Client.get("/loans/sale-summaries/available", opts)
  end

  @doc "Get summaries for already-sold loans."
  @spec get_sold_summaries(opts()) :: result()
  def get_sold_summaries(opts \\ []) do
    Client.get("/loans/sale-summaries/sold", opts)
  end
end
