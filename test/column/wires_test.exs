defmodule Column.WiresTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create/2" do
    test "creates a domestic wire", %{bypass: bypass, config: config} do
      wire = Fixtures.wire_transfer()
      stub_json(bypass, "POST", "/transfers/wire", 200, wire)

      assert {:ok, result} =
               Column.Wires.create(
                 %{
                   bank_account_id: "bacc_123",
                   counterparty_id: "cpty_456",
                   amount: 100_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert result["id"] == "wire_test123"
    end
  end

  describe "drawdown requests" do
    test "creates a drawdown request", %{bypass: bypass, config: config} do
      req = %{"id" => "wddr_123", "status" => "PENDING", "amount" => 50_000}
      stub_json(bypass, "POST", "/transfers/wire/drawdown-requests", 200, req)

      assert {:ok, result} =
               Column.Wires.create_drawdown_request(
                 %{
                   bank_account_id: "bacc_123",
                   counterparty_id: "cpty_456",
                   amount: 50_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert result["id"] == "wddr_123"
    end

    test "approves a drawdown request", %{bypass: bypass, config: config} do
      approved = %{"id" => "wddr_123", "status" => "APPROVED"}
      stub_json(bypass, "POST", "/transfers/wire/drawdown-requests/wddr_123/approve", 200, approved)

      assert {:ok, result} = Column.Wires.approve_drawdown_request("wddr_123", config: config)
      assert result["status"] == "APPROVED"
    end
  end

  describe "return requests" do
    test "approves a return request", %{bypass: bypass, config: config} do
      approved = %{"id" => "wrr_123", "status" => "APPROVED"}
      stub_json(bypass, "POST", "/transfers/wire/return-requests/wrr_123/approve", 200, approved)

      assert {:ok, result} = Column.Wires.approve_return_request("wrr_123", config: config)
      assert result["status"] == "APPROVED"
    end

    test "rejects a return request", %{bypass: bypass, config: config} do
      rejected = %{"id" => "wrr_123", "status" => "REJECTED"}
      stub_json(bypass, "POST", "/transfers/wire/return-requests/wrr_123/reject", 200, rejected)

      assert {:ok, result} = Column.Wires.reject_return_request("wrr_123", %{}, config: config)
      assert result["status"] == "REJECTED"
    end
  end
end
