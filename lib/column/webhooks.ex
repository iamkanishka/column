defmodule Column.Webhooks do
  @moduledoc """
  Webhook endpoint registration and delivery management.

  Register HTTPS endpoints to receive real-time event push notifications.
  Column retries failed deliveries with exponential backoff.
  All deliveries are logged and queryable.

  ## Registering a webhook

      {:ok, wh} = Column.Webhooks.create(%{
        url: "https://your-app.com/webhooks/column",
        description: "Production event sink",
        enabled_events: ["transfer.ach.settled", "transfer.wire.settled"]
      })

      # Verify ownership (Column sends a challenge to your endpoint)
      {:ok, _} = Column.Webhooks.verify(wh["id"])

  ## Verifying webhook signatures

  Column signs every delivery with HMAC-SHA256. Use `verify_signature/3` to
  validate incoming webhook payloads in your endpoint handler.

      def handle_webhook(conn) do
        sig = List.first(get_req_header(conn, "column-signature"))
        raw_body = conn.assigns[:raw_body]
        secret = System.get_env("COLUMN_WEBHOOK_SECRET")

        case Column.Webhooks.verify_signature(raw_body, sig, secret) do
          :ok -> process(conn)
          :error -> send_resp(conn, 401, "Invalid signature")
        end
      end
  """

  import Bitwise, only: [|||: 2]

  alias Column.Client

  @type id :: String.t()
  @type params :: map()
  @type opts :: keyword()
  @type result :: {:ok, map()} | {:error, Column.Error.t()}

  @doc "Create a webhook endpoint."
  @spec create(params(), opts()) :: result()
  def create(params, opts \\ []) do
    Client.post("/webhooks", params, opts)
  end

  @doc "List all webhook endpoints."
  @spec list(opts()) :: result()
  def list(opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/webhooks", Keyword.put(opts, :params, params))
  end

  @doc "Get a webhook endpoint by ID."
  @spec get(id(), opts()) :: result()
  def get(id, opts \\ []) do
    Client.get("/webhooks/#{id}", opts)
  end

  @doc "Update a webhook endpoint."
  @spec update(id(), params(), opts()) :: result()
  def update(id, params, opts \\ []) do
    Client.patch("/webhooks/#{id}", params, opts)
  end

  @doc "Delete a webhook endpoint."
  @spec delete(id(), opts()) :: result()
  def delete(id, opts \\ []) do
    Client.delete("/webhooks/#{id}", opts)
  end

  @doc "Trigger endpoint verification (Column sends a challenge request to your URL)."
  @spec verify(id(), opts()) :: result()
  def verify(id, opts \\ []) do
    Client.post("/webhooks/#{id}/verify", nil, opts)
  end

  @doc "List all deliveries for a webhook endpoint."
  @spec list_deliveries(id(), opts()) :: result()
  def list_deliveries(id, opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/webhooks/#{id}/deliveries", Keyword.put(opts, :params, params))
  end

  @doc "List webhook deliveries grouped by event."
  @spec list_deliveries_by_event(id(), opts()) :: result()
  def list_deliveries_by_event(id, opts \\ []) do
    params = Enum.into(Keyword.take(opts, [:limit, :starting_after, :ending_before]), %{})
    Client.get("/webhooks/#{id}/deliveries/by-event", Keyword.put(opts, :params, params))
  end

  @doc """
  Verify a webhook signature from an incoming delivery.

  Column signs each delivery with HMAC-SHA256 using your webhook secret.
  Always validate signatures before processing webhook payloads.

  Returns `:ok` if valid, `:error` if invalid or missing.
  """
  @spec verify_signature(binary(), String.t() | nil, String.t()) :: :ok | :error
  def verify_signature(_body, nil, _secret), do: :error
  def verify_signature(_body, _sig, nil), do: :error

  def verify_signature(body, signature, secret) do
    expected = Base.encode16(:crypto.mac(:hmac, :sha256, secret, body), case: :lower)

    actual = String.downcase(signature)

    if secure_compare(expected, actual), do: :ok, else: :error
  rescue
    _ -> :error
  end

  # Constant-time binary comparison to prevent timing attacks.
  @spec secure_compare(binary(), binary()) :: boolean()
  defp secure_compare(a, b) when byte_size(a) != byte_size(b), do: false

  defp secure_compare(a, b) do
    :crypto.hash_equals(a, b)
  rescue
    # OTP < 25 doesn't have hash_equals; fall back to XOR fold
    _ ->
      a
      |> :binary.bin_to_list()
      |> Enum.zip(:binary.bin_to_list(b))
      |> Enum.reduce(0, fn {x, y}, acc -> acc ||| Bitwise.bxor(x, y) end)
      |> Kernel.==(0)
  end
end
