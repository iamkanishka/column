defmodule Column.RateLimitTest do
  use ExUnit.Case, async: true

  alias Column.RateLimit

  describe "from_headers/1" do
    test "parses all rate limit headers" do
      now_unix = DateTime.to_unix(DateTime.utc_now()) + 60

      headers = %{
        "x-ratelimit-limit" => ["100"],
        "x-ratelimit-remaining" => ["42"],
        "x-ratelimit-reset" => [Integer.to_string(now_unix)],
        "retry-after" => ["5"]
      }

      info = RateLimit.from_headers(headers)
      assert info.limit == 100
      assert info.remaining == 42
      assert %DateTime{} = info.reset_at
      assert info.retry_after_ms == 5_000
    end

    test "handles missing headers gracefully" do
      info = RateLimit.from_headers(%{})
      assert info.limit == nil
      assert info.remaining == nil
      assert info.reset_at == nil
      assert info.retry_after_ms == nil
    end
  end

  describe "exhausted?/1" do
    test "returns true when remaining is 0" do
      assert RateLimit.exhausted?(%RateLimit{remaining: 0})
    end

    test "returns false when remaining > 0" do
      refute RateLimit.exhausted?(%RateLimit{remaining: 10})
    end

    test "returns false when remaining is nil" do
      refute RateLimit.exhausted?(%RateLimit{remaining: nil})
    end
  end

  describe "from_error_raw/1" do
    test "extracts retry_after when present" do
      info = RateLimit.from_error_raw(%{"retry_after" => 30})
      assert info.retry_after_ms == 30_000
    end

    test "returns empty struct for nil" do
      info = RateLimit.from_error_raw(nil)
      assert info.retry_after_ms == nil
    end
  end
end
