defmodule Column.Idempotency do
  @moduledoc """
  Idempotency key generation and management.

  Column supports idempotent POST requests via the `Idempotency-Key` header.
  Keys are stored for 30 days and must be:
  - Maximum 255 characters
  - ASCII printable characters only

  The Column client auto-generates a random key for every POST request.
  Use this module when you need deterministic, business-logic-derived keys.

  ## Strategies

  ### UUID (default — random, non-deterministic)

      key = Column.Idempotency.uuid()
      Column.ACH.create(%{...}, idempotency_key: key)

  ### Deterministic (content-addressed)

  Use when the same business operation must map to the same key,
  even across process restarts or retries from a job queue:

      key = Column.Idempotency.for_transfer(:ach, order_id: "ord_123", attempt: 1)
      # => "ach:ord_123:1"

      key = Column.Idempotency.hash("ach", %{order_id: "ord_123", amount: 10_000})
      # => "ach:a3f2c8..." (SHA256-derived, always same for same inputs)

  ### Namespaced

      key = Column.Idempotency.namespaced("payroll", "run_456", "june-2024")
      # => "payroll:run_456:june-2024"

  ## Validation

      Column.Idempotency.valid?("my-key")  # => true
      Column.Idempotency.valid?("x" <> String.duplicate("a", 255))  # => false (too long)
  """

  @max_length 255

  @doc "Generate a random UUID v4 idempotency key."
  @spec uuid() :: String.t()
  def uuid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
    |> then(fn hex ->
      <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>> = hex

      "#{a}-#{b}-#{c}-#{d}-#{e}"
    end)
  end

  @doc """
  Build a namespaced idempotency key from parts.

  All parts are joined with `:` and validated.

      Column.Idempotency.namespaced("payroll", "run_456", "2024-06")
      # => "payroll:run_456:2024-06"
  """
  @spec namespaced(String.t(), String.t(), String.t()) :: String.t()
  def namespaced(namespace, id, qualifier) do
    key = Enum.join([namespace, id, qualifier], ":")
    if valid?(key), do: key, else: raise(ArgumentError, "Idempotency key too long: #{key}")
  end

  @doc """
  Build a deterministic content-addressed key from a namespace and a map of params.

  The map is JSON-encoded, SHA256-hashed, and prefixed with the namespace.
  This produces the same key for the same logical operation across retries.

      Column.Idempotency.hash("ach_credit", %{order_id: "ord_123", amount: 5000})
      # => "ach_credit:3d2e1f..."
  """
  @spec hash(String.t(), map()) :: String.t()
  def hash(namespace, params) when is_map(params) do
    # Sort keys for deterministic ordering, then hash with :crypto
    sorted =
      params
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> inspect()

    digest = Base.encode16(:crypto.hash(:sha256, sorted), case: :lower)
    "#{namespace}:#{String.slice(digest, 0, 32)}"
  end

  @doc "Build a key from keyword list of fields."
  @spec for_transfer(atom(), keyword()) :: String.t()
  def for_transfer(type, fields) when is_atom(type) and is_list(fields) do
    parts = [to_string(type) | Enum.map(fields, fn {_k, v} -> to_string(v) end)]
    key = Enum.join(parts, ":")

    if valid?(key) do
      key
    else
      # fall back to hash if key would be too long
      hash(to_string(type), Map.new(fields))
    end
  end

  @doc "Returns true if the key is valid for use as an idempotency key."
  @spec valid?(String.t()) :: boolean()
  def valid?(key) when is_binary(key) do
    byte_size(key) <= @max_length and String.printable?(key) and
      not String.contains?(key, ["\n", "\r", "\t"])
  end

  def valid?(_), do: false
end
