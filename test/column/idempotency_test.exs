defmodule Column.IdempotencyTest do
  use ExUnit.Case, async: true

  alias Column.Idempotency

  describe "uuid/0" do
    test "generates valid UUID format" do
      key = Idempotency.uuid()
      assert Regex.match?(~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/, key)
    end

    test "generates unique keys each call" do
      keys = for _ <- 1..100, do: Idempotency.uuid()
      assert length(Enum.uniq(keys)) == 100
    end
  end

  describe "namespaced/3" do
    test "joins parts with colons" do
      key = Idempotency.namespaced("payroll", "run_456", "2024-06")
      assert key == "payroll:run_456:2024-06"
    end

    test "validates resulting key" do
      assert Idempotency.valid?(Idempotency.namespaced("a", "b", "c"))
    end
  end

  describe "hash/2" do
    test "produces deterministic output" do
      key1 = Idempotency.hash("ach", %{order_id: "ord_123", amount: 5_000})
      key2 = Idempotency.hash("ach", %{order_id: "ord_123", amount: 5_000})
      assert key1 == key2
    end

    test "differs for different inputs" do
      key1 = Idempotency.hash("ach", %{order_id: "ord_123"})
      key2 = Idempotency.hash("ach", %{order_id: "ord_456"})
      refute key1 == key2
    end

    test "result is valid" do
      key = Idempotency.hash("ach_credit", %{order_id: "ord_123"})
      assert Idempotency.valid?(key)
    end
  end

  describe "for_transfer/2" do
    test "builds a colon-separated key from fields" do
      key = Idempotency.for_transfer(:ach, order_id: "ord_123", attempt: 1)
      assert key == "ach:ord_123:1"
    end
  end

  describe "valid?/1" do
    test "accepts printable strings under 255 chars" do
      assert Idempotency.valid?("valid-key-123")
      assert Idempotency.valid?(String.duplicate("a", 255))
    end

    test "rejects over-length keys" do
      refute Idempotency.valid?(String.duplicate("a", 256))
    end

    test "rejects keys with newlines" do
      refute Idempotency.valid?("key\nwith\nnewline")
    end

    test "rejects non-binary" do
      refute Idempotency.valid?(123)
      refute Idempotency.valid?(nil)
    end
  end
end
