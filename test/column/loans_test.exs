defmodule Column.LoansTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "loan CRUD" do
    test "creates a loan", %{bypass: bypass, config: config} do
      loan = Fixtures.loan()
      stub_json(bypass, "POST", "/loans", 200, loan)

      assert {:ok, result} =
               Column.Loans.create(
                 %{
                   loan_program_id: "lpgm_123",
                   bank_account_id: "bacc_456",
                   amount: 500_000
                 },
                 config: config
               )

      assert result["id"] == "loan_test123"
    end

    test "lists loans", %{bypass: bypass, config: config} do
      loans = Fixtures.list_response([Fixtures.loan()])
      stub_json(bypass, "GET", "/loans", 200, loans)

      assert {:ok, result} = Column.Loans.list(config: config)
      assert length(result["data"]) == 1
    end

    test "gets loan summary", %{bypass: bypass, config: config} do
      summary = %{"data" => [%{"date" => "2024-01-01", "principal_balance" => 500_000}]}
      stub_json(bypass, "GET", "/loans/loan_test123/summary", 200, summary)

      assert {:ok, result} = Column.Loans.get_summary("loan_test123", config: config)
      assert length(result["data"]) == 1
    end
  end

  describe "loan programs" do
    test "lists programs", %{bypass: bypass, config: config} do
      programs = Fixtures.list_response([%{"id" => "lpgm_123", "name" => "Standard"}])
      stub_json(bypass, "GET", "/loans/programs", 200, programs)

      assert {:ok, result} = Column.Loans.list_programs(config: config)
      assert length(result["data"]) == 1
    end
  end

  describe "loan sales" do
    test "creates a loan sale", %{bypass: bypass, config: config} do
      sale = %{"id" => "lsale_123", "status" => "COMPLETED"}
      stub_json(bypass, "POST", "/loans/loan_test123/sales", 200, sale)

      assert {:ok, result} =
               Column.Loans.create_sale(
                 "loan_test123",
                 %{buyer_entity_id: "ent_789"},
                 config: config
               )

      assert result["id"] == "lsale_123"
    end
  end
end
