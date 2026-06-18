defmodule Column.Telemetry do
  @moduledoc """
  Telemetry integration for the Column HTTP client.

  The Column client emits the following `:telemetry` events:

  ### `[:column, :request, :start]`

  Emitted before each HTTP request is dispatched.

  **Measurements:** `%{system_time: integer()}`

  **Metadata:** `%{method: atom(), path: String.t(), attempt: non_neg_integer()}`

  ### `[:column, :request, :stop]`

  Emitted after a successful or failed HTTP request.

  **Measurements:** `%{duration: integer()}` (in native time units)

  **Metadata:**
  ```
  %{
    method: atom(),
    path: String.t(),
    status: non_neg_integer() | nil,
    attempt: non_neg_integer(),
    result: :ok | :error,
    error_type: atom() | nil
  }
  ```

  ### `[:column, :request, :exception]`

  Emitted when an unexpected exception occurs in the client pipeline.

  **Measurements:** `%{duration: integer()}`

  **Metadata:** `%{method: atom(), path: String.t(), kind: atom(), reason: term()}`

  ### `[:column, :retry]`

  Emitted each time a request is retried due to a transient error.

  **Measurements:** `%{attempt: non_neg_integer(), delay_ms: non_neg_integer()}`

  **Metadata:** `%{method: atom(), path: String.t(), status: non_neg_integer()}`

  ## Setup

  Attach handlers in your application start:

      :telemetry.attach_many(
        "column-logger",
        [
          [:column, :request, :start],
          [:column, :request, :stop],
          [:column, :retry]
        ],
        &Column.Telemetry.handle_event/4,
        %{}
      )

  ## Integration with `telemetry_metrics`

      [
        Telemetry.Metrics.counter("column.request.stop.count",
          tags: [:method, :status, :result]
        ),
        Telemetry.Metrics.distribution("column.request.stop.duration",
          unit: {:native, :millisecond},
          tags: [:method, :result]
        ),
        Telemetry.Metrics.counter("column.retry.count",
          tags: [:method, :status]
        )
      ]
  """

  require Logger

  @doc "A simple built-in logger handler for development. Attach with `Column.Telemetry.attach_logger/1`."
  @spec attach_logger(Logger.level()) :: :ok | {:error, :already_exists}
  def attach_logger(level \\ :debug) do
    :telemetry.attach_many(
      "column-default-logger",
      [
        [:column, :request, :start],
        [:column, :request, :stop],
        [:column, :request, :exception],
        [:column, :retry]
      ],
      &__MODULE__.handle_event/4,
      %{level: level}
    )
  end

  @doc false
  @spec handle_event(list(), map(), map(), map()) :: :ok
  def handle_event([:column, :request, :start], _measurements, meta, config) do
    level = Map.get(config, :level, :debug)

    Logger.log(
      level,
      "[Column] #{String.upcase(to_string(meta.method))} #{meta.path} (attempt #{meta.attempt})"
    )
  end

  def handle_event([:column, :request, :stop], %{duration: duration}, meta, config) do
    level = Map.get(config, :level, :debug)
    ms = System.convert_time_unit(duration, :native, :millisecond)

    Logger.log(
      level,
      "[Column] #{String.upcase(to_string(meta.method))} #{meta.path} → #{meta.status} #{meta.result} (#{ms}ms)"
    )
  end

  def handle_event([:column, :request, :exception], %{duration: duration}, meta, _config) do
    ms = System.convert_time_unit(duration, :native, :millisecond)
    method_str = String.upcase(to_string(meta.method))
    reason_str = inspect(meta.reason)

    Logger.error("[Column] #{method_str} #{meta.path} raised #{meta.kind}: #{reason_str} (#{ms}ms)")
  end

  def handle_event([:column, :retry], %{attempt: attempt, delay_ms: delay_ms}, meta, config) do
    level = Map.get(config, :level, :debug)
    method_str = String.upcase(to_string(meta.method))

    Logger.log(
      level,
      "[Column] Retrying #{method_str} #{meta.path} after HTTP #{meta.status}" <>
        " (attempt #{attempt}, delay #{delay_ms}ms)"
    )
  end

  @doc "Emit a telemetry start event."
  @spec start(atom(), String.t(), non_neg_integer()) :: integer()
  def start(method, path, attempt) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:column, :request, :start],
      %{system_time: System.system_time()},
      %{method: method, path: path, attempt: attempt}
    )

    start_time
  end

  @doc "Emit a telemetry stop event."
  @spec stop(integer(), atom(), String.t(), non_neg_integer(), non_neg_integer() | nil, atom()) ::
          :ok
  def stop(start_time, method, path, attempt, status, result) do
    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      [:column, :request, :stop],
      %{duration: duration},
      %{
        method: method,
        path: path,
        attempt: attempt,
        status: status,
        result: result,
        error_type: nil
      }
    )
  end

  @doc "Emit a telemetry retry event."
  @spec emit_retry(atom(), String.t(), non_neg_integer(), non_neg_integer()) :: :ok
  def emit_retry(method, path, status, delay_ms) do
    :telemetry.execute(
      [:column, :retry],
      %{attempt: 1, delay_ms: delay_ms},
      %{method: method, path: path, status: status}
    )
  end
end
