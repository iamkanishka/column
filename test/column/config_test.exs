defmodule Column.ConfigTest do
  use ExUnit.Case, async: true

  alias Column.Config

  describe "new/1" do
    test "uses application env defaults" do
      config = Config.new()
      assert config.base_url == "https://api.column.com"
      assert config.max_retries == 3
    end

    test "overrides with keyword args" do
      config = Config.new(api_key: "test_key", max_retries: 0)
      assert config.api_key == "test_key"
      assert config.max_retries == 0
    end
  end

  describe "validate!/1" do
    test "raises on nil api_key" do
      assert_raise ArgumentError, ~r/API key is required/, fn ->
        Config.validate!(%Config{api_key: nil})
      end
    end

    test "raises on empty api_key" do
      assert_raise ArgumentError, ~r/must not be empty/, fn ->
        Config.validate!(%Config{api_key: ""})
      end
    end

    test "returns config when valid" do
      config = %Config{api_key: "test_key"}
      assert Config.validate!(config) == config
    end
  end
end
