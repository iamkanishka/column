defmodule Column.RealtimeTransfers do
  @moduledoc """
  Instant payments via RTP (The Clearing House) and FedNow.

  Realtime transfers settle in seconds, 24/7/365.
  Supports Request for Payment (RFP) to pull funds from a counterparty,
  and return request flows.

  ## Sending a realtime payment

      {:ok, transfer} = Column.RealtimeTransfers.create(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        amount: 25_000,
        currency_code: "USD",
        description: "Rent payment"
      })

  ## Request for Payment (RFP)

      {:ok, rfp} = Column.RealtimeTransfers.create_rfp(%{
        bank_account_id: "bacc_123",
        counterparty_id: "cpty_456",
        amount: 500_00,
        currency_code: "USD",
        expiration: "2024-06-30T00:00:00Z"
      })

      # Counterparty accepts or rejects via their bank
      Column.RealtimeTransfers.accept_rfp(rfp["id"])
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  # ---------------------------------------------------------------------------
  # Transfers
  # ---------------------------------------------------------------------------

  @doc "Create a realtime transfer."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/transfers/realtime", params, opts)
  end

  @doc "List all realtime transfers."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before, :bank_account_id]), %{})
    Client.get("/transfers/realtime", Keyword.put(opts, :params, params))
  end

  @doc "Get a realtime transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/realtime/#{id}", opts)
  end

  @doc "Return an incoming realtime transfer."
  @spec return_incoming(id(), params(), opts()) :: result()
  def return_incoming(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/realtime/#{id}/return", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Requests for Payment (RFPs)
  # ---------------------------------------------------------------------------

  @doc "Create a realtime Request for Payment."
  @spec create_rfp(params(), opts()) :: result()
  def create_rfp(params, opts \\ []) do
    Client.post("/transfers/realtime/rfps", params, opts)
  end

  @doc "List all realtime RFPs."
  @spec list_rfps(opts()) :: result()
  def list_rfps(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/transfers/realtime/rfps", Keyword.put(opts, :params, params))
  end

  @doc "Get a realtime RFP by ID."
  @spec get_rfp(id(), opts()) :: result()
  def get_rfp(id, opts \\ []) do
    Client.get("/transfers/realtime/rfps/#{id}", opts)
  end

  @doc "Accept a realtime RFP."
  @spec accept_rfp(id(), params(), opts()) :: result()
  def accept_rfp(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/realtime/rfps/#{id}/accept", params, opts)
  end

  @doc "Reject a realtime RFP."
  @spec reject_rfp(id(), params(), opts()) :: result()
  def reject_rfp(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/realtime/rfps/#{id}/reject", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Return requests
  # ---------------------------------------------------------------------------

  @doc "Create a realtime return request."
  @spec create_return_request(params(), opts()) :: result()
  def create_return_request(params, opts \\ []) do
    Client.post("/transfers/realtime/return-requests", params, opts)
  end

  @doc "List all realtime return requests."
  @spec list_return_requests(opts()) :: result()
  def list_return_requests(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/transfers/realtime/return-requests", Keyword.put(opts, :params, params))
  end

  @doc "Get a realtime return request."
  @spec get_return_request(id(), opts()) :: result()
  def get_return_request(id, opts \\ []) do
    Client.get("/transfers/realtime/return-requests/#{id}", opts)
  end

  @doc "Accept a realtime return request."
  @spec accept_return_request(id(), params(), opts()) :: result()
  def accept_return_request(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/realtime/return-requests/#{id}/accept", params, opts)
  end

  @doc "Reject a realtime return request."
  @spec reject_return_request(id(), params(), opts()) :: result()
  def reject_return_request(id, params \\ %{}, opts \\ []) do
    Client.post("/transfers/realtime/return-requests/#{id}/reject", params, opts)
  end
end
