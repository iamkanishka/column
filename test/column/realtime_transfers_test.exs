defmodule Column.RealtimeTransfersTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create/2" do
    test "creates a realtime transfer", %{bypass: bypass, config: config} do
      rt = %{"id" => "rt_123", "status" => "SETTLED", "amount" => 25_000}
      stub_json(bypass, "POST", "/transfers/realtime", 200, rt)

      assert {:ok, result} =
               Column.RealtimeTransfers.create(
                 %{
                   bank_account_id: "bacc_123",
                   counterparty_id: "cpty_456",
                   amount: 25_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert result["id"] == "rt_123"
    end
  end

  describe "RFP lifecycle" do
    test "creates, accepts, and rejects RFPs", %{bypass: bypass, config: config} do
      rfp = %{"id" => "rfp_123", "status" => "PENDING", "amount" => 50_000}

      stub_json(bypass, "POST", "/transfers/realtime/rfps", 200, rfp)

      assert {:ok, created} =
               Column.RealtimeTransfers.create_rfp(
                 %{
                   bank_account_id: "bacc_123",
                   amount: 50_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert created["id"] == "rfp_123"

      accepted = Map.put(rfp, "status", "ACCEPTED")
      stub_json(bypass, "POST", "/transfers/realtime/rfps/rfp_123/accept", 200, accepted)
      assert {:ok, a} = Column.RealtimeTransfers.accept_rfp("rfp_123", %{}, config: config)
      assert a["status"] == "ACCEPTED"
    end
  end

  describe "return requests" do
    test "accepts and rejects return requests", %{bypass: bypass, config: config} do
      rr = %{"id" => "rtrr_123", "status" => "ACCEPTED"}
      stub_json(bypass, "POST", "/transfers/realtime/return-requests/rtrr_123/accept", 200, rr)

      assert {:ok, result} = Column.RealtimeTransfers.accept_return_request("rtrr_123", %{}, config: config)
      assert result["status"] == "ACCEPTED"
    end
  end
end
