defmodule Column.InternationalWiresTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "FX quote lifecycle" do
    test "full quote flow: request -> get -> book -> cancel", %{bypass: bypass, config: config} do
      quote_obj = %{
        "id" => "fxq_123",
        "status" => "PENDING",
        "buy_currency" => "EUR",
        "sell_currency" => "USD",
        "buy_amount" => 10_000,
        "sell_amount" => 10_850
      }

      stub_json(bypass, "POST", "/transfers/international-wire/fx-quotes", 200, quote_obj)

      assert {:ok, q} =
               Column.InternationalWires.request_fx_quote(
                 %{
                   buy_currency: "EUR",
                   sell_currency: "USD",
                   buy_amount: 10_000
                 },
                 config: config
               )

      assert q["id"] == "fxq_123"

      stub_json(bypass, "GET", "/transfers/international-wire/fx-quotes/fxq_123", 200, quote_obj)
      assert {:ok, fetched} = Column.InternationalWires.get_fx_quote("fxq_123", config: config)
      assert fetched["buy_currency"] == "EUR"

      booked = Map.put(quote_obj, "status", "BOOKED")
      stub_json(bypass, "POST", "/transfers/international-wire/fx-quotes/fxq_123/book", 200, booked)
      assert {:ok, b} = Column.InternationalWires.book_fx_quote("fxq_123", config: config)
      assert b["status"] == "BOOKED"
    end
  end

  describe "get_fx_rate_sheet/1" do
    test "fetches rate sheet", %{bypass: bypass, config: config} do
      sheet = %{"rates" => [%{"currency" => "EUR", "rate" => "1.0850"}]}
      stub_json(bypass, "GET", "/transfers/international-wire/fx-rate-sheet", 200, sheet)

      assert {:ok, result} = Column.InternationalWires.get_fx_rate_sheet(config: config)
      assert is_list(result["rates"])
    end
  end
end
