defmodule Column.AccountNumbers do
  @moduledoc """
  Virtual account number management.

  Create multiple routing+account number pairs per bank account.
  Each unique account number can be issued to a different customer
  while routing to a single underlying bank account (FBO/sweep pattern).

  ## Example

      {:ok, acct_num} = Column.AccountNumbers.create("bacc_123", %{
        description: "Customer A virtual account"
      })
  """

  alias Column.Client

  @type bank_account_id :: String.t()
  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create an account number for a bank account."
  @spec create(bank_account_id(), params(), opts()) :: result()
  def create(bank_account_id, params, opts \\ []) do
    Client.post("/bank-accounts/#{bank_account_id}/account-numbers", params, opts)
  end

  @doc "List all account numbers for a bank account."
  @spec list(bank_account_id(), opts()) :: result()
  def list(bank_account_id, opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/bank-accounts/#{bank_account_id}/account-numbers", Keyword.put(opts, :params, params))
  end

  @doc "Get an account number."
  @spec get(bank_account_id(), id(), opts()) :: result()
  def get(bank_account_id, id, opts \\ []) do
    Client.get("/bank-accounts/#{bank_account_id}/account-numbers/#{id}", opts)
  end

  @doc "Update an account number."
  @spec update(bank_account_id(), id(), params(), opts()) :: result()
  def update(bank_account_id, id, params, opts \\ []) do
    Client.patch("/bank-accounts/#{bank_account_id}/account-numbers/#{id}", params, opts)
  end
end
