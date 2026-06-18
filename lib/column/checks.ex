defmodule Column.Checks do
  @moduledoc """
  Check issuance and remote deposit capture.

  ## Issue a check (Column prints and mails)

      {:ok, check} = Column.Checks.issue(%{
        bank_account_id: "bacc_123",
        amount: 50_000,
        currency_code: "USD",
        payee_name: "Jane Smith",
        memo: "Invoice #999",
        mailing_address: %{
          line_1: "456 Oak Ave",
          city: "Austin",
          state: "TX",
          postal_code: "78701"
        }
      })

      # Preview before issuing
      {:ok, pdf_bytes} = Column.Checks.get_preview(check["id"])

  ## Deposit a check (remote deposit capture)

      {:ok, deposit} = Column.Checks.deposit(%{
        bank_account_id: "bacc_456",
        amount: 10_000,
        currency_code: "USD"
      })
      Column.Checks.capture_front(deposit["id"], "/tmp/check_front.jpg")
      Column.Checks.capture_back(deposit["id"], "/tmp/check_back.jpg")
  """

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Issue a check (Column prints and mails it)."
  @spec issue(params(), opts()) :: result()
  def issue(params, opts \\ []) do
    Client.post("/transfers/checks/issue", params, opts)
  end

  @doc "Initiate a check deposit (remote deposit capture)."
  @spec deposit(params(), opts()) :: result()
  def deposit(params, opts \\ []) do
    Client.post("/transfers/checks/deposit", params, opts)
  end

  @doc "Upload the front image of a check deposit."
  @spec capture_front(id(), String.t(), opts()) :: result()
  def capture_front(id, file_path, opts \\ []) do
    parts = [{:file, file_path, filename: Path.basename(file_path)}]
    Client.post_multipart("/transfers/checks/#{id}/capture-front", parts, opts)
  end

  @doc "Upload the back image of a check deposit."
  @spec capture_back(id(), String.t(), opts()) :: result()
  def capture_back(id, file_path, opts \\ []) do
    parts = [{:file, file_path, filename: Path.basename(file_path)}]
    Client.post_multipart("/transfers/checks/#{id}/capture-back", parts, opts)
  end

  @doc "List all check transfers."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before, :bank_account_id, :type]), %{})
    Client.get("/transfers/checks", Keyword.put(opts, :params, params))
  end

  @doc "Get a check transfer by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/transfers/checks/#{id}", opts)
  end

  @doc "Get a PDF preview of an issued check."
  @spec get_preview(id(), opts()) :: result()
  def get_preview(id, opts \\ []) do
    Client.get("/transfers/checks/#{id}/preview", opts)
  end

  @doc "Stop a check transfer."
  @spec stop(id(), opts()) :: result()
  def stop(id, opts \\ []) do
    Client.post("/transfers/checks/#{id}/stop", nil, opts)
  end

  @doc "Create a return for a check transfer."
  @spec create_return(id(), params(), opts()) :: result()
  def create_return(id, params, opts \\ []) do
    Client.post("/transfers/checks/#{id}/returns", params, opts)
  end

  @doc "Get returns for a check transfer."
  @spec get_returns(id(), opts()) :: result()
  def get_returns(id, opts \\ []) do
    Client.get("/transfers/checks/#{id}/returns", opts)
  end

  @doc "List all check returns across all check transfers."
  @spec list_returns(opts()) :: result()
  def list_returns(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/transfers/checks/returns", Keyword.put(opts, :params, params))
  end
end
