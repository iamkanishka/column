defmodule Column.RateLimit do
  @moduledoc """
  Rate limit information parsed from Column API response headers.

  Column includes rate limit headers on API responses. This struct
  captures that information for observability and backoff decisions.

  ## Headers parsed

  - `x-ratelimit-limit` — Maximum requests allowed in the window
  - `x-ratelimit-remaining` — Remaining requests in current window
  - `x-ratelimit-reset` — Unix timestamp when the window resets
  - `retry-after` — Seconds to wait before retrying (on 429 responses)

  ## Usage

      case Column.ACH.create(%{...}) do
        {:ok, result} -> result
        {:error, %Column.Error{status: 429, raw: raw}} ->
          info = Column.RateLimit.from_error_raw(raw)
          Process.sleep(info.retry_after_ms || 1_000)
          # retry...
      end
  """

  @type t :: %__MODULE__{
          limit: non_neg_integer() | nil,
          remaining: non_neg_integer() | nil,
          reset_at: DateTime.t() | nil,
          retry_after_ms: non_neg_integer() | nil
        }

  defstruct limit: nil,
            remaining: nil,
            reset_at: nil,
            retry_after_ms: nil

  # Req represents response headers as a map of header-name => list-of-values,
  # e.g. %{"x-ratelimit-limit" => ["100"]}.
  @type headers :: %{optional(String.t()) => [String.t()]}

  @doc "Parse rate limit info from Req-style response headers (a map of lists)."
  @spec from_headers(headers()) :: t()
  def from_headers(headers) when is_map(headers) do
    %__MODULE__{
      limit: parse_int_header(headers, "x-ratelimit-limit"),
      remaining: parse_int_header(headers, "x-ratelimit-remaining"),
      reset_at: parse_reset(headers),
      retry_after_ms: parse_retry_after(headers)
    }
  end

  @doc "Build from error raw body (when you only have the error struct)."
  @spec from_error_raw(map() | nil) :: t()
  def from_error_raw(nil), do: %__MODULE__{}

  def from_error_raw(%{"retry_after" => seconds}) when is_number(seconds) do
    %__MODULE__{retry_after_ms: round(seconds * 1_000)}
  end

  def from_error_raw(_), do: %__MODULE__{}

  @doc "Returns true if the rate limit window is exhausted."
  @spec exhausted?(t()) :: boolean()
  def exhausted?(%__MODULE__{remaining: 0}), do: true
  def exhausted?(%__MODULE__{}), do: false

  @doc "Milliseconds to wait before the rate limit window resets."
  @spec ms_until_reset(t()) :: non_neg_integer() | nil
  def ms_until_reset(%__MODULE__{reset_at: nil}), do: nil

  def ms_until_reset(%__MODULE__{reset_at: reset_at}) do
    diff = DateTime.diff(reset_at, DateTime.utc_now(), :millisecond)
    max(diff, 0)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  @spec first_header_value(headers(), String.t()) :: String.t() | nil
  defp first_header_value(headers, name) do
    case Map.get(headers, name) do
      [value | _] -> value
      _ -> nil
    end
  end

  @spec parse_int_header(headers(), String.t()) :: non_neg_integer() | nil
  defp parse_int_header(headers, name) do
    case first_header_value(headers, name) do
      nil ->
        nil

      value ->
        case Integer.parse(value) do
          {n, _} -> n
          :error -> nil
        end
    end
  end

  @spec parse_reset(headers()) :: DateTime.t() | nil
  defp parse_reset(headers) do
    case parse_int_header(headers, "x-ratelimit-reset") do
      nil ->
        nil

      unix ->
        case DateTime.from_unix(unix) do
          {:ok, dt} -> dt
          _ -> nil
        end
    end
  end

  @spec parse_retry_after(headers()) :: non_neg_integer() | nil
  defp parse_retry_after(headers) do
    case first_header_value(headers, "retry-after") do
      nil ->
        nil

      value ->
        case Integer.parse(value) do
          {seconds, _} -> seconds * 1_000
          :error -> nil
        end
    end
  end
end
