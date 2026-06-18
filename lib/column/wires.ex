defmodule Column.Wires do
  @moduledoc """
  Domestic wire transfers via Fedwire.

  Same-day settlement if submitted before the daily cutoff.
  Supports drawdown requests (pull funds from a third party) and
  return request flows with approve/reject by the receiving bank.

  ## Originating a wire

      {:ok, wire} = Column.Wires.create(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        amount: 100_000,
        currency_code: "USD",
        message_to_beneficiary: "Invoice #1234"
      })

  ## Wire drawdown (pull funds from counterparty)

      {:ok, req} = Column.Wires.create_drawdown_request(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        amount: 50_000,
        currency_code: "USD"
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  # ---------------------------------------------------------------------------
  # Wire transfers
  # ---------------------------------------------------------------------------

  @doc "Create a domestic wire transfer."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/transfers/wire", params, opts)
  end

  @doc "List all domestic wire transfers."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before, :bank_account_id]), %{})
    Client.get("/transfers/wire", Keyword.put(opts, :params, params))
  end

  @doc "Get a domestic wire transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/wire/#{id}", opts)
  end

  @doc "Reverse an incoming domestic wire transfer."
  @spec reverse(id(), params(), opts()) :: result()
  def reverse(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/wire/#{id}/reverse", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Drawdown requests
  # ---------------------------------------------------------------------------

  @doc "Create a wire drawdown request."
  @spec create_drawdown_request(params(), opts()) :: result()
  def create_drawdown_request(params, opts \\ []) do
    Client.post("/transfers/wire/drawdown-requests", params, opts)
  end

  @doc "List all wire drawdown requests."
  @spec list_drawdown_requests(opts()) :: result()
  def list_drawdown_requests(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/transfers/wire/drawdown-requests", Keyword.put(opts, :params, params))
  end

  @doc "Get a wire drawdown request."
  @spec get_drawdown_request(id(), opts()) :: result()
  def get_drawdown_request(id, opts \\ []) do
    Client.get("/transfers/wire/drawdown-requests/#{id}", opts)
  end

  @doc "Approve a wire drawdown request."
  @spec approve_drawdown_request(id(), opts()) :: result()
  def approve_drawdown_request(id, opts \\ []) do
    Client.post("/transfers/wire/drawdown-requests/#{id}/approve", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # Return requests
  # ---------------------------------------------------------------------------

  @doc "Create a wire return request."
  @spec create_return_request(params(), opts()) :: result()
  def create_return_request(params, opts \\ []) do
    Client.post("/transfers/wire/return-requests", params, opts)
  end

  @doc "List all wire return requests."
  @spec list_return_requests(opts()) :: result()
  def list_return_requests(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/transfers/wire/return-requests", Keyword.put(opts, :params, params))
  end

  @doc "Get a wire return request."
  @spec get_return_request(id(), opts()) :: result()
  def get_return_request(id, opts \\ []) do
    Client.get("/transfers/wire/return-requests/#{id}", opts)
  end

  @doc "Approve a wire return request."
  @spec approve_return_request(id(), opts()) :: result()
  def approve_return_request(id, opts \\ []) do
    Client.post("/transfers/wire/return-requests/#{id}/approve", nil, opts)
  end

  @doc "Reject a wire return request."
  @spec reject_return_request(id(), params(), opts()) :: result()
  def reject_return_request(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/wire/return-requests/#{id}/reject", params, opts)
  end
end
