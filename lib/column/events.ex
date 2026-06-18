defmodule Column.Events do
  @moduledoc """
  Immutable audit log of every state change on the Column platform.

  Every object mutation emits a typed event with a `type` string and a `data`
  payload. Use events for reconciliation by polling, or pair with webhooks for
  real-time push delivery.

  ## Common event types

  - `bank_account.created`, `bank_account.updated`
  - `transfer.ach.created`, `transfer.ach.settled`, `transfer.ach.returned`
  - `transfer.wire.created`, `transfer.wire.settled`
  - `transfer.book.created`, `transfer.book.cleared`
  - `transfer.realtime.created`, `transfer.realtime.settled`
  - `transfer.check.issued`, `transfer.check.settled`
  - `loan.created`, `loan.disbursement.cleared`
  - `entity.kyc.approved`, `entity.kyc.denied`

  ## Example

      {:ok, page} = Column.Events.list(limit: 25)
      events = page["data"]
      Enum.each(events, fn event ->
        process_event(event)
      end)
  """

  alias Column.Client

  @type id :: String.t()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "List all events. Supports cursor pagination and optional type filter."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    allowed = [:limit, :starting_after, :ending_before, :type, :bank_account_id]
    params = Enum.into(Keyword.take(opts, allowed), %{})
    Client.get("/events", Keyword.put(opts, :params, params))
  end

  @doc "Get an event by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/events/#{id}", opts)
  end

  @doc "List all available webhook event types."
  @spec list_webhook_event_types(opts()) :: result()
  def list_webhook_event_types(opts \\ []) do
    Client.get("/events/webhook-events", opts)
  end
end
