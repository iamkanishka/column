defmodule Column.Client do
  @moduledoc """
  Low-level HTTP client for the Column API.

  Handles:
  - HTTP Basic Auth (blank username, API key as password)
  - JSON encoding / decoding via Jason
  - Automatic retry with exponential backoff + jitter for transient errors
  - Idempotency-Key header injection on POST requests
  - Rate limit header parsing (X-RateLimit-*)
  - Telemetry events via `Column.Telemetry`
  - Multipart file upload support
  - Structured `Column.Error` on all failure paths
  - Request ID extraction from response headers

  You should not call this module directly — use the resource modules
  (`Column.ACH`, `Column.BankAccounts`, etc.) which delegate here.
  """

  alias Column.Config
  alias Column.Error
  alias Column.RateLimit
  alias Column.Telemetry

  @type response :: {:ok, map() | list()} | {:error, Error.t()}
  @type path :: String.t()
  @type body :: map() | nil
  @type opts :: keyword()

  # Req represents response headers as a map of header-name => list-of-values.
  @type req_headers :: %{optional(String.t()) => [String.t()]}

  # HTTP statuses that warrant a retry
  @retryable_statuses [408, 429, 500, 502, 503, 504]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Perform a GET request."
  @spec get(path(), opts()) :: response()
  def get(path, opts \\ []), do: request(:get, path, nil, opts)

  @doc "Perform a POST request."
  @spec post(path(), body(), opts()) :: response()
  def post(path, body \\ nil, opts \\ []), do: request(:post, path, body, opts)

  @doc "Perform a PATCH request."
  @spec patch(path(), body(), opts()) :: response()
  def patch(path, body \\ nil, opts \\ []), do: request(:patch, path, body, opts)

  @doc "Perform a DELETE request."
  @spec delete(path(), opts()) :: response()
  def delete(path, opts \\ []), do: request(:delete, path, nil, opts)

  @doc "Perform a multipart POST (for file uploads)."
  @spec post_multipart(path(), list(), opts()) :: response()
  def post_multipart(path, parts, opts \\ []) do
    config = resolve_config(opts)
    Config.validate!(config)

    req =
      config
      |> base_req()
      |> Req.merge(url: path, method: :post, form_multipart: parts)
      |> maybe_idempotency_key(opts)
      |> maybe_extra_headers(opts)

    execute_with_retry(req, config, config.max_retries, 0)
  end

  # ---------------------------------------------------------------------------
  # Private — request building
  # ---------------------------------------------------------------------------

  @spec request(atom(), path(), body(), opts()) :: response()
  defp request(method, path, body, opts) do
    config = resolve_config(opts)
    Config.validate!(config)

    req_opts =
      [url: path, method: method]
      |> put_body(body)
      |> put_query_params(opts[:params])

    req =
      config
      |> base_req()
      |> Req.merge(req_opts)
      |> maybe_idempotency_key(opts)
      |> maybe_extra_headers(opts)

    execute_with_retry(req, config, config.max_retries, 0)
  end

  @spec put_body(keyword(), body()) :: keyword()
  defp put_body(req_opts, nil), do: req_opts
  defp put_body(req_opts, body), do: Keyword.put(req_opts, :json, body)

  @spec put_query_params(keyword(), map() | nil) :: keyword()
  defp put_query_params(req_opts, nil), do: req_opts
  defp put_query_params(req_opts, params), do: Keyword.put(req_opts, :params, params)

  @spec base_req(Config.t()) :: Req.Request.t()
  defp base_req(%Config{} = config) do
    Req.new(
      base_url: config.base_url,
      auth: {:basic, ":#{config.api_key}"},
      receive_timeout: config.recv_timeout,
      connect_options: [timeout: config.timeout],
      headers: [
        {"content-type", "application/json"},
        {"accept", "application/json"},
        {"user-agent", "column-elixir/#{column_version()} elixir/#{System.version()}"}
      ],
      retry: false
    )
  end

  # ---------------------------------------------------------------------------
  # Private — retry loop with telemetry
  # ---------------------------------------------------------------------------

  @spec execute_with_retry(Req.Request.t(), Config.t(), non_neg_integer(), non_neg_integer()) ::
          response()
  defp execute_with_retry(req, config, retries_left, attempt) do
    path = URI.to_string(req.url)
    method = req.method
    start_time = Telemetry.start(method, path, attempt)
    ctx = %{path: path, method: method, start_time: start_time, attempt: attempt}

    try do
      do_execute(req, config, retries_left, ctx)
    rescue
      exception ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(
          [:column, :request, :exception],
          %{duration: duration},
          %{method: method, path: path, kind: :error, reason: exception}
        )

        {:error, Error.from_exception(exception)}
    end
  end

  @spec do_execute(Req.Request.t(), Config.t(), non_neg_integer(), map()) :: response()
  defp do_execute(req, config, retries_left, ctx) do
    case Req.request(req) do
      {:ok, %Req.Response{} = resp} ->
        handle_response(resp, req, config, retries_left, ctx)

      {:error, exception} ->
        %{method: method, path: path, start_time: start_time, attempt: attempt} = ctx
        Telemetry.stop(start_time, method, path, attempt, nil, :error)
        {:error, Error.from_exception(exception)}
    end
  end

  @spec handle_response(Req.Response.t(), Req.Request.t(), Config.t(), non_neg_integer(), map()) ::
          response()
  defp handle_response(%Req.Response{status: status} = resp, req, config, retries_left, ctx)
       when status in @retryable_statuses and retries_left > 0 do
    %{method: method, path: path, start_time: start_time, attempt: attempt} = ctx

    rate_info = RateLimit.from_headers(resp.headers)
    delay = compute_delay(config.retry_delay, attempt, rate_info)

    Telemetry.emit_retry(method, path, status, delay)
    Telemetry.stop(start_time, method, path, attempt, status, :error)

    Process.sleep(delay)
    execute_with_retry(req, config, retries_left - 1, attempt + 1)
  end

  defp handle_response(%Req.Response{status: status} = resp, _req, _config, _retries_left, ctx)
       when status in 200..299 do
    %{method: method, path: path, start_time: start_time, attempt: attempt} = ctx

    request_id = get_header(resp.headers, "x-request-id")
    Telemetry.stop(start_time, method, path, attempt, status, :ok)
    {:ok, maybe_add_request_id(resp.body, request_id)}
  end

  defp handle_response(%Req.Response{status: status} = resp, _req, _config, _retries_left, ctx) do
    %{method: method, path: path, start_time: start_time, attempt: attempt} = ctx

    request_id = get_header(resp.headers, "x-request-id")
    err_body = ensure_map(resp.body)
    Telemetry.stop(start_time, method, path, attempt, status, :error)
    {:error, Error.from_response(status, err_body, request_id)}
  end

  # ---------------------------------------------------------------------------
  # Private — helpers
  # ---------------------------------------------------------------------------

  @spec compute_delay(pos_integer(), non_neg_integer(), RateLimit.t()) :: non_neg_integer()
  defp compute_delay(_base_delay, _attempt, %RateLimit{retry_after_ms: ms}) when is_integer(ms) do
    # Respect the Retry-After header from the server when present
    ms
  end

  defp compute_delay(base_delay, attempt, %RateLimit{}) do
    # Exponential backoff: base * 2^attempt, capped at 30s, with ±25% jitter
    exp_delay = min(round(base_delay * :math.pow(2, attempt)), 30_000)
    jitter = :rand.uniform(max(div(exp_delay, 4), 1))
    exp_delay + jitter
  end

  @spec maybe_idempotency_key(Req.Request.t(), opts()) :: Req.Request.t()
  defp maybe_idempotency_key(req, opts) do
    key = resolve_idempotency_key(req, opts)

    if key do
      Req.merge(req, headers: [{"idempotency-key", key}])
    else
      req
    end
  end

  @spec resolve_idempotency_key(Req.Request.t(), opts()) :: String.t() | nil
  defp resolve_idempotency_key(req, opts) do
    case opts[:idempotency_key] do
      nil -> if req.method == :post, do: generate_idempotency_key(), else: nil
      key -> key
    end
  end

  @spec maybe_extra_headers(Req.Request.t(), opts()) :: Req.Request.t()
  defp maybe_extra_headers(req, opts) do
    case opts[:headers] do
      nil -> req
      headers -> Req.merge(req, headers: headers)
    end
  end

  @spec resolve_config(opts()) :: Config.t()
  defp resolve_config(opts) do
    case opts[:config] do
      %Config{} = c -> c
      nil -> Config.new()
    end
  end

  @spec generate_idempotency_key() :: String.t()
  defp generate_idempotency_key do
    Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
  end

  # Req represents response headers as %{String.t() => [String.t()]}.
  @spec get_header(req_headers(), String.t()) :: String.t() | nil
  defp get_header(headers, name) do
    case Map.get(headers, name) do
      [value | _] -> value
      _ -> nil
    end
  end

  @spec maybe_add_request_id(term(), String.t() | nil) :: term()
  defp maybe_add_request_id(%{} = body, request_id) when is_binary(request_id) do
    Map.put_new(body, "_request_id", request_id)
  end

  defp maybe_add_request_id(body, _request_id), do: body

  @spec ensure_map(term()) :: map()
  defp ensure_map(%{} = m), do: m
  defp ensure_map(_), do: %{}

  @spec column_version() :: String.t()
  defp column_version do
    to_string(Application.spec(:column, :vsn))
  rescue
    _ -> "unknown"
  end
end
