defmodule Column.BankAccountsTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "create/2" do
    test "creates a bank account", %{bypass: bypass, config: config} do
      account = Fixtures.bank_account()
      stub_json(bypass, "POST", "/bank-accounts", 200, account)

      assert {:ok, result} = Column.BankAccounts.create(%{description: "Test"}, config: config)
      assert result["id"] == "bacc_test123"
    end

    test "returns error on 422", %{bypass: bypass, config: config} do
      stub_json(
        bypass,
        "POST",
        "/bank-accounts",
        422,
        Fixtures.error_response("VALIDATION_ERROR", "description is required")
      )

      assert {:error, err} = Column.BankAccounts.create(%{}, config: config)
      assert err.status == 422
      assert err.type == :api_error
      assert err.code == "VALIDATION_ERROR"
    end
  end

  describe "list/1" do
    test "lists bank accounts", %{bypass: bypass, config: config} do
      accounts = Fixtures.list_response([Fixtures.bank_account()])
      stub_json(bypass, "GET", "/bank-accounts", 200, accounts)

      assert {:ok, result} = Column.BankAccounts.list(config: config)
      assert length(result["data"]) == 1
      assert result["has_more"] == false
    end
  end

  describe "get/2" do
    test "gets a bank account by id", %{bypass: bypass, config: config} do
      account = Fixtures.bank_account()
      stub_json(bypass, "GET", "/bank-accounts/bacc_test123", 200, account)

      assert {:ok, result} = Column.BankAccounts.get("bacc_test123", config: config)
      assert result["id"] == "bacc_test123"
    end

    test "returns 404 error", %{bypass: bypass, config: config} do
      stub_json(
        bypass,
        "GET",
        "/bank-accounts/bacc_missing",
        404,
        Fixtures.error_response("NOT_FOUND", "Bank account not found")
      )

      assert {:error, err} = Column.BankAccounts.get("bacc_missing", config: config)
      assert err.status == 404
    end
  end

  describe "update/3" do
    test "updates a bank account", %{bypass: bypass, config: config} do
      updated = Fixtures.bank_account(%{"description" => "Updated"})
      stub_json(bypass, "PATCH", "/bank-accounts/bacc_test123", 200, updated)

      assert {:ok, result} =
               Column.BankAccounts.update(
                 "bacc_test123",
                 %{description: "Updated"},
                 config: config
               )

      assert result["description"] == "Updated"
    end
  end

  describe "delete/2" do
    test "deletes a bank account", %{bypass: bypass, config: config} do
      stub_json(bypass, "DELETE", "/bank-accounts/bacc_test123", 200, %{})

      assert {:ok, _} = Column.BankAccounts.delete("bacc_test123", config: config)
    end
  end

  describe "get_summary/2" do
    test "gets balance history", %{bypass: bypass, config: config} do
      summary = %{"data" => [%{"date" => "2024-01-01", "balance" => 100_000}]}
      stub_json(bypass, "GET", "/bank-accounts/bacc_test123/summary", 200, summary)

      assert {:ok, result} = Column.BankAccounts.get_summary("bacc_test123", config: config)
      assert length(result["data"]) == 1
    end
  end
end
