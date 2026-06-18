defmodule Column.ACHTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create/2" do
    test "creates an ACH credit", %{bypass: bypass, config: config} do
      transfer = Fixtures.ach_transfer()

      stub_json_with_body(bypass, "POST", "/transfers/ach", 200, transfer, fn body ->
        decoded = Jason.decode!(body)
        assert decoded["type"] == "CREDIT"
      end)

      assert {:ok, result} =
               Column.ACH.create(
                 %{
                   bank_account_id: "bacc_123",
                   counterparty_id: "cpty_456",
                   amount: 10_000,
                   currency_code: "USD",
                   type: "CREDIT",
                   entry_class_code: "PPD"
                 },
                 config: config
               )

      assert result["id"] == "acht_test123"
      assert result["type"] == "CREDIT"
    end
  end

  describe "list/1" do
    test "lists ACH transfers", %{bypass: bypass, config: config} do
      transfers = Fixtures.list_response([Fixtures.ach_transfer()])
      stub_json(bypass, "GET", "/transfers/ach", 200, transfers)

      assert {:ok, result} = Column.ACH.list(config: config)
      assert length(result["data"]) == 1
    end
  end

  describe "cancel/2" do
    test "cancels an ACH transfer", %{bypass: bypass, config: config} do
      cancelled = Fixtures.ach_transfer(%{"status" => "CANCELLED"})
      stub_json(bypass, "POST", "/transfers/ach/acht_test123/cancel", 200, cancelled)

      assert {:ok, result} = Column.ACH.cancel("acht_test123", config: config)
      assert result["status"] == "CANCELLED"
    end
  end

  describe "reverse/3" do
    test "reverses an ACH transfer", %{bypass: bypass, config: config} do
      reversed = Fixtures.ach_transfer(%{"status" => "REVERSED"})
      stub_json(bypass, "POST", "/transfers/ach/acht_test123/reverse", 200, reversed)

      assert {:ok, result} = Column.ACH.reverse("acht_test123", %{}, config: config)
      assert result["status"] == "REVERSED"
    end
  end

  describe "create_return/3" do
    test "creates an ACH return", %{bypass: bypass, config: config} do
      return = %{"id" => "achret_123", "return_code" => "R01"}
      stub_json(bypass, "POST", "/transfers/ach/acht_test123/returns", 200, return)

      assert {:ok, result} =
               Column.ACH.create_return(
                 "acht_test123",
                 %{return_code: "R01"},
                 config: config
               )

      assert result["return_code"] == "R01"
    end
  end

  describe "positive pay rules" do
    test "creates a positive pay rule", %{bypass: bypass, config: config} do
      rule = %{"id" => "ppr_123", "company_name" => "EMPLOYER"}
      stub_json(bypass, "POST", "/ach-positive-pay-rules", 200, rule)

      assert {:ok, result} =
               Column.ACH.create_positive_pay_rule(
                 %{
                   company_name: "EMPLOYER"
                 },
                 config: config
               )

      assert result["id"] == "ppr_123"
    end

    test "deletes a positive pay rule", %{bypass: bypass, config: config} do
      stub_json(bypass, "DELETE", "/ach-positive-pay-rules/ppr_123", 200, %{})

      assert {:ok, _} = Column.ACH.delete_positive_pay_rule("ppr_123", config: config)
    end
  end
end
