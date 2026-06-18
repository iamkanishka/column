defmodule Column.ParamsTest do
  use ExUnit.Case, async: true

  alias Column.Params

  describe "put_required/3" do
    test "adds the field when value is present" do
      result = Params.new() |> Params.put_required(:amount, 1_000) |> Params.build!()
      assert result["amount"] == 1_000
    end

    test "records error when value is nil" do
      builder = Params.put_required(Params.new(), :amount, nil)
      assert {:error, err} = Params.build(builder)
      assert err.message =~ "amount is required"
    end

    test "records error when value is empty string" do
      builder = Params.put_required(Params.new(), :name, "")
      assert {:error, err} = Params.build(builder)
      assert err.message =~ "name must not be empty"
    end
  end

  describe "put_optional/3" do
    test "omits nil values" do
      result = Params.new() |> Params.put_optional(:description, nil) |> Params.build!()
      refute Map.has_key?(result, "description")
    end

    test "includes non-nil values" do
      result = Params.new() |> Params.put_optional(:description, "test") |> Params.build!()
      assert result["description"] == "test"
    end
  end

  describe "validate_amount/2" do
    test "passes valid positive integer" do
      result =
        Params.new()
        |> Params.put_required(:amount, 500)
        |> Params.validate_amount(:amount)
        |> Params.build!()

      assert result["amount"] == 500
    end

    test "records error for zero amount" do
      builder =
        Params.new()
        |> Params.put_required(:amount, 0)
        |> Params.validate_amount(:amount)

      assert {:error, err} = Params.build(builder)
      assert err.message =~ "amount must be a positive integer"
    end

    test "records error for float" do
      builder =
        Params.new()
        |> Params.put_required(:amount, 10.5)
        |> Params.validate_amount(:amount)

      assert {:error, err} = Params.build(builder)
      assert err.message =~ "amount must be a positive integer"
    end
  end

  describe "validate_inclusion/3" do
    test "passes when value is in allowed list" do
      result =
        Params.new()
        |> Params.put_required(:type, "CREDIT")
        |> Params.validate_inclusion(:type, ["CREDIT", "DEBIT"])
        |> Params.build!()

      assert result["type"] == "CREDIT"
    end

    test "records error when value not in list" do
      builder =
        Params.new()
        |> Params.put_required(:type, "INVALID")
        |> Params.validate_inclusion(:type, ["CREDIT", "DEBIT"])

      assert {:error, err} = Params.build(builder)
      assert err.message =~ "type must be one of"
    end
  end

  describe "build!/1 with multiple errors" do
    test "raises with concatenated messages" do
      assert_raise Column.Error, ~r/amount is required.*bank_account_id is required/s, fn ->
        Params.new()
        |> Params.put_required(:amount, nil)
        |> Params.put_required(:bank_account_id, nil)
        |> Params.build!()
      end
    end
  end

  describe "real-world ACH param building" do
    test "builds a valid ACH credit param map" do
      result =
        Params.new()
        |> Params.put_required(:bank_account_id, "bacc_123")
        |> Params.put_required(:counterparty_id, "cpty_456")
        |> Params.put_required(:amount, 10_000)
        |> Params.put_required(:currency_code, "USD")
        |> Params.put_required(:type, "CREDIT")
        |> Params.put_optional(:entry_class_code, "PPD")
        |> Params.put_optional(:effective_date, nil)
        |> Params.validate_amount(:amount)
        |> Params.validate_currency(:currency_code)
        |> Params.validate_inclusion(:type, ["CREDIT", "DEBIT"])
        |> Params.build!()

      assert result["bank_account_id"] == "bacc_123"
      assert result["amount"] == 10_000
      assert result["type"] == "CREDIT"
      refute Map.has_key?(result, "effective_date")
    end
  end
end
