defmodule Column.DisbursementsTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "hold lifecycle" do
    test "create -> clear flow", %{bypass: bypass, config: config} do
      held = %{"id" => "disb_123", "status" => "ON_HOLD", "amount" => 500_000}
      stub_json(bypass, "POST", "/loans/disbursements", 200, held)

      assert {:ok, d} =
               Column.Disbursements.create(
                 %{
                   loan_id: "loan_123",
                   bank_account_id: "bacc_456",
                   amount: 500_000,
                   currency_code: "USD",
                   hold: true
                 },
                 config: config
               )

      assert d["status"] == "ON_HOLD"

      cleared = Map.put(held, "status", "SETTLED")
      stub_json(bypass, "POST", "/loans/disbursements/disb_123/clear", 200, cleared)
      assert {:ok, c} = Column.Disbursements.clear("disb_123", config: config)
      assert c["status"] == "SETTLED"
    end

    test "create -> cancel flow", %{bypass: bypass, config: config} do
      held = %{"id" => "disb_124", "status" => "ON_HOLD"}
      stub_json(bypass, "POST", "/loans/disbursements", 200, held)

      assert {:ok, d} =
               Column.Disbursements.create(
                 %{loan_id: "loan_123", bank_account_id: "bacc_456", amount: 100_000, hold: true},
                 config: config
               )

      cancelled = Map.put(held, "status", "CANCELLED")
      stub_json(bypass, "POST", "/loans/disbursements/disb_124/cancel", 200, cancelled)
      assert {:ok, c} = Column.Disbursements.cancel("disb_124", config: config)
      assert c["status"] == "CANCELLED"
    end
  end
end
