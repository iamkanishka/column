defmodule Column.Simulation do
  @moduledoc """
  Sandbox simulation endpoints.

  Trigger real network events synthetically in the sandbox environment
  so you can test end-to-end flows without external parties or waiting
  for actual network settlement windows.

  **These endpoints only work in the sandbox environment.**
  Calling them against a production API key will return a 403 error.

  ## Test a full ACH credit flow

      # 1. Simulate an inbound ACH credit arriving
      {:ok, _} = Column.Simulation.receive_ach_credit(%{
        bank_account_id: "bacc_123",
        amount: 100_000,
        currency_code: "USD",
        company_name: "EMPLOYER CORP",
        entry_class_code: "PPD"
      })

      # 2. Settle the resulting ACH transfer
      {:ok, transfers} = Column.ACH.list(bank_account_id: "bacc_123")
      transfer_id = hd(transfers["data"])["id"]
      {:ok, _} = Column.Simulation.settle_ach(transfer_id)

  ## Test a realtime RFP

      {:ok, _} = Column.Simulation.receive_realtime_rfp(%{
        bank_account_id: "bacc_123",
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
  # ACH simulation
  # ---------------------------------------------------------------------------

  @doc "Simulate receiving an inbound ACH credit."
  @spec receive_ach_credit(params(), opts()) :: result()
  def receive_ach_credit(params, opts \\ []) do
    Client.post("/simulate/ach/receive-credit", params, opts)
  end

  @doc "Simulate receiving an inbound ACH debit."
  @spec receive_ach_debit(params(), opts()) :: result()
  def receive_ach_debit(params, opts \\ []) do
    Client.post("/simulate/ach/receive-debit", params, opts)
  end

  @doc "Simulate settling an ACH transfer."
  @spec settle_ach(id(), opts()) :: result()
  def settle_ach(id, opts \\ []) do
    Client.post("/simulate/ach/#{id}/settle", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # Wire simulation
  # ---------------------------------------------------------------------------

  @doc "Simulate receiving an inbound domestic wire."
  @spec receive_wire(params(), opts()) :: result()
  def receive_wire(params, opts \\ []) do
    Client.post("/simulate/wire/receive", params, opts)
  end

  @doc "Simulate receiving a wire drawdown request."
  @spec receive_wire_drawdown_request(params(), opts()) :: result()
  def receive_wire_drawdown_request(params, opts \\ []) do
    Client.post("/simulate/wire/drawdown-request", params, opts)
  end

  @doc "Simulate receiving a wire return request."
  @spec receive_wire_return_request(params(), opts()) :: result()
  def receive_wire_return_request(params, opts \\ []) do
    Client.post("/simulate/wire/return-request", params, opts)
  end

  @doc "Simulate settling a domestic wire transfer."
  @spec settle_wire(id(), opts()) :: result()
  def settle_wire(id, opts \\ []) do
    Client.post("/simulate/wire/#{id}/settle", nil, opts)
  end

  # ---------------------------------------------------------------------------
  # International wire simulation
  # ---------------------------------------------------------------------------

  @doc "Simulate receiving an inbound international wire."
  @spec receive_international_wire(params(), opts()) :: result()
  def receive_international_wire(params, opts \\ []) do
    Client.post("/simulate/international-wire/receive", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Realtime simulation
  # ---------------------------------------------------------------------------

  @doc "Simulate receiving an inbound realtime transfer."
  @spec receive_realtime(params(), opts()) :: result()
  def receive_realtime(params, opts \\ []) do
    Client.post("/simulate/realtime/receive", params, opts)
  end

  @doc "Simulate receiving a realtime Request for Payment."
  @spec receive_realtime_rfp(params(), opts()) :: result()
  def receive_realtime_rfp(params, opts \\ []) do
    Client.post("/simulate/realtime/rfp", params, opts)
  end

  # ---------------------------------------------------------------------------
  # Check simulation
  # ---------------------------------------------------------------------------

  @doc "Simulate depositing an issued check (sandbox only)."
  @spec deposit_check(params(), opts()) :: result()
  def deposit_check(params, opts \\ []) do
    Client.post("/simulate/checks/deposit", params, opts)
  end

  @doc "Simulate settling a check deposit."
  @spec settle_check(id(), opts()) :: result()
  def settle_check(id, opts \\ []) do
    Client.post("/simulate/checks/#{id}/settle", nil, opts)
  end
end
