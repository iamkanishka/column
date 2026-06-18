defmodule Column.TelemetryTest do
  use ExUnit.Case, async: true

  alias Column.Telemetry

  describe "start/3" do
    test "emits :start event and returns monotonic time" do
      test_pid = self()

      :telemetry.attach(
        "test-start-#{System.unique_integer()}",
        [:column, :request, :start],
        fn _event, measurements, meta, _ ->
          send(test_pid, {:telemetry, :start, measurements, meta})
        end,
        nil
      )

      start_time = Telemetry.start(:get, "/bank-accounts", 0)
      assert is_integer(start_time)

      assert_receive {:telemetry, :start, %{system_time: _}, %{method: :get, path: "/bank-accounts", attempt: 0}}
    end
  end

  describe "stop/6" do
    test "emits :stop event with duration" do
      test_pid = self()

      :telemetry.attach(
        "test-stop-#{System.unique_integer()}",
        [:column, :request, :stop],
        fn _event, measurements, meta, _ ->
          send(test_pid, {:telemetry, :stop, measurements, meta})
        end,
        nil
      )

      start = System.monotonic_time()
      Telemetry.stop(start, :post, "/transfers/ach", 0, 200, :ok)

      assert_receive {:telemetry, :stop, %{duration: dur},
                      %{method: :post, path: "/transfers/ach", status: 200, result: :ok}}

      assert is_integer(dur) and dur >= 0
    end
  end

  describe "emit_retry/4" do
    test "emits :retry event" do
      test_pid = self()

      :telemetry.attach(
        "test-retry-#{System.unique_integer()}",
        [:column, :retry],
        fn _event, measurements, meta, _ ->
          send(test_pid, {:telemetry, :retry, measurements, meta})
        end,
        nil
      )

      Telemetry.emit_retry(:post, "/transfers/ach", 503, 500)

      assert_receive {:telemetry, :retry, %{delay_ms: 500}, %{method: :post, path: "/transfers/ach", status: 503}}
    end
  end
end
