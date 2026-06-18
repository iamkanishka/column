defmodule Column.Test.Fixtures do
  @moduledoc "Shared test fixtures."

  def bank_account(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "bacc_test123",
        "description" => "Test account",
        "status" => "OPEN",
        "available_balance" => 100_000,
        "pending_balance" => 0,
        "currency_code" => "USD",
        "created_at" => "2024-01-01T00:00:00Z",
        "updated_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def entity_person(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "ent_person123",
        "type" => "person",
        "first_name" => "Ada",
        "last_name" => "Lovelace",
        "email" => "ada@example.com",
        "kyc_status" => "APPROVED",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def entity_business(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "ent_biz123",
        "type" => "business",
        "business_name" => "Acme Corp",
        "kyb_status" => "APPROVED",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def ach_transfer(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "acht_test123",
        "type" => "CREDIT",
        "status" => "PENDING",
        "amount" => 10_000,
        "currency_code" => "USD",
        "entry_class_code" => "PPD",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def book_transfer(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "book_test123",
        "status" => "SETTLED",
        "amount" => 5_000,
        "currency_code" => "USD",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def wire_transfer(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "wire_test123",
        "status" => "PENDING",
        "amount" => 100_000,
        "currency_code" => "USD",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def counterparty(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "cpty_test123",
        "name" => "Jane Smith",
        "routing_number" => "121000248",
        "account_number" => "000123456789",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def loan(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "loan_test123",
        "status" => "ACTIVE",
        "principal" => 500_000,
        "currency_code" => "USD",
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def webhook(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "wh_test123",
        "url" => "https://example.com/webhooks",
        "status" => "ACTIVE",
        "enabled_events" => ["transfer.ach.settled"],
        "created_at" => "2024-01-01T00:00:00Z"
      },
      overrides
    )
  end

  def list_response(items, overrides \\ %{}) do
    Map.merge(
      %{
        "data" => items,
        "has_more" => false
      },
      overrides
    )
  end

  def error_response(code, message) do
    %{"code" => code, "message" => message}
  end
end
