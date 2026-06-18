defmodule Column.MoneyTest do
  use ExUnit.Case, async: true

  alias Column.Money

  describe "to_cents/2" do
    test "passthrough for integers" do
      assert Money.to_cents(1_000, "USD") == 1_000
    end

    test "converts float USD correctly" do
      assert Money.to_cents(10.50, "USD") == 1_050
      assert Money.to_cents(0.01, "USD") == 1
      assert Money.to_cents(99.99, "USD") == 9_999
    end

    test "handles zero decimals for JPY" do
      assert Money.to_cents(1_000.0, "JPY") == 1_000
    end
  end

  describe "from_cents/2" do
    test "converts USD cents to decimal string" do
      assert Money.from_cents(1_050, "USD") == "10.50"
      assert Money.from_cents(100, "USD") == "1.00"
      assert Money.from_cents(1, "USD") == "0.01"
    end

    test "handles zero-decimal currencies" do
      assert Money.from_cents(1_000, "JPY") == "1000"
    end

    test "pads decimal places correctly" do
      assert Money.from_cents(5, "USD") == "0.05"
    end
  end

  describe "format/2" do
    test "formats USD with $ symbol and commas" do
      assert Money.format(100_000, "USD") == "$1,000.00"
      assert Money.format(100_000_000, "USD") == "$1,000,000.00"
    end

    test "formats EUR with € symbol" do
      assert Money.format(500, "EUR") == "€5.00"
    end

    test "formats JPY without decimal" do
      assert Money.format(1_000, "JPY") == "¥1,000"
    end
  end

  describe "valid_amount?/1" do
    test "returns true for positive integer" do
      assert Money.valid_amount?(100)
      assert Money.valid_amount?(1)
    end

    test "returns false for zero, negatives, non-integers" do
      refute Money.valid_amount?(0)
      refute Money.valid_amount?(-1)
      refute Money.valid_amount?(10.5)
      refute Money.valid_amount?("100")
      refute Money.valid_amount?(nil)
    end
  end
end
