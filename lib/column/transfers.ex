defmodule Column.Transfers do
  @moduledoc """
  Unified transfer list across all payment types.

  Query ACH, wire, book, realtime, and check transfers from one endpoint.
  Useful for building ledger views, reconciliation dashboards, and
  activity feeds without making per-type requests.

  ## Example

      {:ok, page} = Column.Transfers.list(
        bank_account_id: "bacc_123",
        limit: 25
      )

      # Stream all transfers without pagination boilerplate
      stream = Column.Pagination.stream(&Column.Transfers.list/1, limit: 100)
      Enum.filter(stream, fn transfer -> transfer["status"] == "SETTLED" end)
  """

  alias Column.Client

  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc """
  List all transfers across all types.

  Optional filters: `bank_account_id`, `type`, `status`, `limit`,
  `starting_after`, `ending_before`.
  """
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [:limit, :starting_after, :ending_before, :bank_account_id, :type, :status]
    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/transfers", Keyword.put(opts, :params, params))
  end
end
