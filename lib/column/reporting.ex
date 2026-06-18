defmodule Column.Reporting do
  @moduledoc """
  Settlement reports and bank account statements.

  Schedule and download CSV/PDF settlement reports. Generate custom
  bank account statements for any date range, useful for reconciliation,
  accounting exports, and regulatory reporting.

  ## Schedule and download a settlement report

      {:ok, report} = Column.Reporting.schedule_settlement_report(%{
        date: "2024-06-01",
        format: "csv"
      })

      # Poll until ready, then download
      {:ok, report} = Column.Reporting.get_settlement_report(report["id"])
      # report["url"] is a signed download URL when status == "ready"

  ## Custom bank account statement

      {:ok, statement} = Column.Reporting.get_bank_account_statement(%{
        bank_account_id: "bacc_123",
        start_date: "2024-01-01",
        end_date: "2024-06-30",
        format: "pdf"
      })
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Schedule a settlement report."
  @spec schedule_settlement_report(params(), opts()) :: result()
  def schedule_settlement_report(params, opts \\ []) do
    Client.post("/reporting/settlement-reports", params, opts)
  end

  @doc "List all settlement reports."
  @spec list_settlement_reports(opts()) :: result()
  def list_settlement_reports(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/reporting/settlement-reports", Keyword.put(opts, :params, params))
  end

  @doc "Get a settlement report by ID."
  @spec get_settlement_report(id(), opts()) :: result()
  def get_settlement_report(id, opts \\ []) do
    Client.get("/reporting/settlement-reports/#{id}", opts)
  end

  @doc "Get a customized bank account statement for a date range."
  @spec get_bank_account_statement(params(), opts()) :: result()
  def get_bank_account_statement(params, opts \\ []) do
    Client.get("/reporting/bank-account-statement", Keyword.put(opts, :params, params))
  end
end
