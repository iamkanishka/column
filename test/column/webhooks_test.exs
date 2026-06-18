defmodule Column.WebhooksTest do
  use ExUnit.Case, async: true

  import Column.Test.BypassHelpers
  alias Column.Test.Fixtures

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass, config: bypass_config(bypass)}
  end

  describe "CRUD" do
    test "creates a webhook", %{bypass: bypass, config: config} do
      wh = Fixtures.webhook()
      stub_json(bypass, "POST", "/webhooks", 200, wh)

      assert {:ok, result} =
               Column.Webhooks.create(
                 %{
                   url: "https://example.com/webhooks"
                 },
                 config: config
               )

      assert result["id"] == "wh_test123"
    end

    test "lists webhooks", %{bypass: bypass, config: config} do
      webhooks = Fixtures.list_response([Fixtures.webhook()])
      stub_json(bypass, "GET", "/webhooks", 200, webhooks)

      assert {:ok, result} = Column.Webhooks.list(config: config)
      assert length(result["data"]) == 1
    end

    test "deletes a webhook", %{bypass: bypass, config: config} do
      stub_json(bypass, "DELETE", "/webhooks/wh_test123", 200, %{})
      assert {:ok, _} = Column.Webhooks.delete("wh_test123", config: config)
    end
  end

  describe "verify_signature/3" do
    test "returns :ok for valid signature" do
      secret = "whsec_test"
      body = ~s({"type":"transfer.ach.settled"})
      sig = Base.encode16(:crypto.mac(:hmac, :sha256, secret, body), case: :lower)

      assert :ok = Column.Webhooks.verify_signature(body, sig, secret)
    end

    test "returns :error for invalid signature" do
      assert :error = Column.Webhooks.verify_signature("body", "bad_sig", "secret")
    end

    test "returns :error when signature is nil" do
      assert :error = Column.Webhooks.verify_signature("body", nil, "secret")
    end

    test "returns :error when secret is nil" do
      assert :error = Column.Webhooks.verify_signature("body", "sig", nil)
    end
  end
end
