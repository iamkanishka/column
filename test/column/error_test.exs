defmodule Column.ErrorTest do
  use ExUnit.Case, async: true

  alias Column.Error

  describe "from_response/3" do
    test "extracts message, code, and request_id" do
      body = %{"message" => "Not found", "code" => "RESOURCE_NOT_FOUND"}
      err = Error.from_response(404, body, "req_abc")

      assert err.type == :api_error
      assert err.status == 404
      assert err.message == "Not found"
      assert err.code == "RESOURCE_NOT_FOUND"
      assert err.request_id == "req_abc"
      assert err.raw == body
    end

    test "handles missing fields gracefully" do
      err = Error.from_response(500, %{}, nil)
      assert err.message == "Unknown API error"
      assert err.code == nil
      assert err.request_id == nil
    end
  end

  describe "validation/1" do
    test "builds a validation error" do
      err = Error.validation("amount must be positive")
      assert err.type == :validation_error
      assert err.message == "amount must be positive"
    end
  end

  describe "message/1" do
    test "includes status code when present" do
      err = %Error{type: :api_error, message: "Not found", status: 404}
      assert Exception.message(err) == "HTTP 404: Not found"
    end

    test "omits status when nil" do
      err = %Error{type: :network_error, message: "timeout"}
      assert Exception.message(err) == "timeout"
    end
  end
end
