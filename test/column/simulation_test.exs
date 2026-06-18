defmodule Column.SimulationTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "ACH simulation" do
    test "receive_ach_credit/2", %{bypass: bypass, config: config} do
      resp = %{"id" => "acht_sim123", "type" => "CREDIT", "status" => "PENDING"}
      stub_json(bypass, "POST", "/simulate/ach/receive-credit", 200, resp)

      assert {:ok, result} =
               Column.Simulation.receive_ach_credit(
                 %{
                   bank_account_id: "bacc_123",
                   amount: 100_000,
                   currency_code: "USD"
                 },
                 config: config
               )

      assert result["type"] == "CREDIT"
    end

    test "settle_ach/2", %{bypass: bypass, config: config} do
      settled = %{"id" => "acht_sim123", "status" => "SETTLED"}
      stub_json(bypass, "POST", "/simulate/ach/acht_sim123/settle", 200, settled)

      assert {:ok, result} = Column.Simulation.settle_ach("acht_sim123", config: config)
      assert result["status"] == "SETTLED"
    end
  end

  describe "wire simulation" do
    test "receive_wire/2", %{bypass: bypass, config: config} do
      wire = %{"id" => "wire_sim123", "status" => "PENDING"}
      stub_json(bypass, "POST", "/simulate/wire/receive", 200, wire)

      assert {:ok, _} =
               Column.Simulation.receive_wire(
                 %{
                   bank_account_id: "bacc_123",
                   amount: 50_000,
                   currency_code: "USD"
                 },
                 config: config
               )
    end
  end

  describe "realtime simulation" do
    test "receive_realtime/2", %{bypass: bypass, config: config} do
      rt = %{"id" => "rt_sim123", "status" => "SETTLED"}
      stub_json(bypass, "POST", "/simulate/realtime/receive", 200, rt)

      assert {:ok, _} =
               Column.Simulation.receive_realtime(
                 %{
                   bank_account_id: "bacc_123",
                   amount: 10_000,
                   currency_code: "USD"
                 },
                 config: config
               )
    end
  end
end
