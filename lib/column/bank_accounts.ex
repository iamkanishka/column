defmodule Column.BankAccounts do
  @moduledoc """
  FDIC-insured bank account management.

  Account types: `:fbo`, `:sweep`, `:clearing`, `:custom`.
  Account state controls transfer eligibility. Supports multiple owners
  and balance history snapshots.

  ## Example

      {:ok, account} = Column.BankAccounts.create(%{
        description: "Customer wallet",
        entity_id: "ent_123",
        account_type: "checking"
      })

      {:ok, summary} = Column.BankAccounts.get_summary(account["id"])
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a new bank account."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/bank-accounts", params, opts)
  end

  @doc "List all bank accounts. Supports cursor pagination."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/bank-accounts", Keyword.put(opts, :params, params))
  end

  @doc "Get a bank account by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/bank-accounts/#{id}", opts)
  end

  @doc "Update a bank account."
  @spec update(id(), params(), opts()) :: result()
  def update(id, params, opts \\ []) do
    Client.patch("/bank-accounts/#{id}", params, opts)
  end

  @doc "Add an owner to a bank account."
  @spec add_owner(id(), params(), opts()) :: result()
  def add_owner(id, params, opts \\ []) do
    Client.post("/bank-accounts/#{id}/owners", params, opts)
  end

  @doc "Delete a bank account."
  @spec delete(id(), opts()) :: result()
  def delete(id, opts \\ []) do
    Client.delete("/bank-accounts/#{id}", opts)
  end

  @doc "Get balance summary history (snapshots) for a bank account."
  @spec get_summary(id(), opts()) :: result()
  def get_summary(id, opts \\ []) do
    Client.get("/bank-accounts/#{id}/summary", opts)
  end
end
