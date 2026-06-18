defmodule Column.BookTransfersTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create/2" do
    test "creates a book transfer", %{bypass: bypass, config: config} do
      transfer = Fixtures.book_transfer()
      stub_json(bypass, "POST", "/transfers/book", 200, transfer)

      assert {:ok, result} =
               Column.BookTransfers.create(
                 %{
                   sender_bank_account_id: "bacc_aaa",
                   receiver_bank_account_id: "bacc_bbb",
                   amount: 5_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert result["id"] == "book_test123"
    end
  end

  describe "hold lifecycle" do
    test "clears a held book transfer", %{bypass: bypass, config: config} do
      cleared = Fixtures.book_transfer(%{"status" => "SETTLED"})
      stub_json(bypass, "POST", "/transfers/book/book_test123/clear", 200, cleared)

      assert {:ok, result} = Column.BookTransfers.clear("book_test123", config: config)
      assert result["status"] == "SETTLED"
    end

    test "cancels a held book transfer", %{bypass: bypass, config: config} do
      cancelled = Fixtures.book_transfer(%{"status" => "CANCELLED"})
      stub_json(bypass, "POST", "/transfers/book/book_test123/cancel", 200, cancelled)

      assert {:ok, result} = Column.BookTransfers.cancel("book_test123", config: config)
      assert result["status"] == "CANCELLED"
    end
  end
end
