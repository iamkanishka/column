defmodule Column.Counterparties do
  @moduledoc """
  External party management for ACH, wire, and international payments.

  Counterparties store routing number, account number, name, and optionally
  an IBAN for international payments.

  ## Example

      {:ok, cpty} = Column.Counterparties.create(%{
        routing_number: "121000248",
        account_number: "000123456789",
        account_type: "checking",
        name: "Jane Smith"
      })

      {:ok, _} = Column.Counterparties.validate_iban("DE89370400440532013000")
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a counterparty."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/counterparties", params, opts)
  end

  @doc "List all counterparties. Supports cursor pagination."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/counterparties", Keyword.put(opts, :params, params))
  end

  @doc "Get a counterparty by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/counterparties/#{id}", opts)
  end

  @doc "Delete a counterparty."
  @spec delete(id(), opts()) :: result()
  def delete(id, opts \\ []) do
    Client.delete("/counterparties/#{id}", opts)
  end

  @doc "Validate an IBAN."
  @spec validate_iban(String.t(), opts()) :: result()
  def validate_iban(iban, opts \\ []) do
    Client.post("/counterparties/iban/validate", %{iban: iban}, opts)
  end

  @doc "List financial institutions (routing number search)."
  @spec list_financial_institutions(opts()) :: result()
  def list_financial_institutions(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:routing_number, :name, :limit]), %{})
    Client.get("/financial-institutions", Keyword.put(opts, :params, params))
  end

  @doc "Get a financial institution by routing number."
  @spec get_financial_institution(String.t(), opts()) :: result()
  def get_financial_institution(routing_number, opts \\ []) do
    Client.get("/financial-institutions/#{routing_number}", opts)
  end
end
