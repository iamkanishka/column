defmodule Column.Pagination do
  @moduledoc """
  Helpers for working with Column's cursor-based pagination.

  Column paginates all list endpoints using `starting_after` / `ending_before`
  cursors (mutually exclusive), returning objects in inverse chronological order.
  Responses always include a `has_more` boolean.

  ## Automatic streaming

  `stream/3` wraps any list function into an `Elixir.Stream`, lazily fetching
  pages as you consume items:

      Column.BankAccounts.list()
      |> Column.Pagination.stream(&Column.BankAccounts.list/1, limit: 50)
      |> Enum.take(200)

  ## Manual pagination

      {:ok, page1} = Column.BankAccounts.list(limit: 10)
      if page1["has_more"] do
        last_id = page1["data"] |> List.last() |> Map.get("id")
        {:ok, page2} = Column.BankAccounts.list(limit: 10, starting_after: last_id)
      end
  """

  @type page :: %{
          String.t() => list(map()) | boolean() | any()
        }

  @type list_fn :: (keyword() -> {:ok, page()} | {:error, Column.Error.t()})

  # Concrete shape produced by build_params/1 and threaded through maybe_put/3.
  @type pagination_param_key :: String.t()
  @type pagination_param_value :: pos_integer() | String.t() | nil
  @type pagination_params :: %{optional(pagination_param_key()) => pagination_param_value()}

  @doc """
  Builds pagination query params from a keyword list, validating constraints.
  """
  @spec build_params(keyword()) :: {:ok, pagination_params()} | {:error, String.t()}
  def build_params(opts) do
    cond do
      opts[:starting_after] && opts[:ending_before] ->
        {:error, "starting_after and ending_before are mutually exclusive"}

      (limit = opts[:limit]) && (limit < 1 || limit > 100) ->
        {:error, "limit must be between 1 and 100"}

      true ->
        params =
          %{}
          |> maybe_put("limit", opts[:limit])
          |> maybe_put("starting_after", opts[:starting_after])
          |> maybe_put("ending_before", opts[:ending_before])

        {:ok, params}
    end
  end

  @doc """
  Wraps a Column list function in a lazy `Stream`, automatically following
  `has_more` cursors. Each emitted element is a single resource map.

      stream = Column.Pagination.stream(&Column.Entities.list/1, limit: 50)
      Enum.each(stream, fn entity -> process(entity) end)
  """
  @spec stream(list_fn(), keyword()) :: Enumerable.t()
  def stream(list_fn, opts \\ []) when is_function(list_fn, 1) do
    Stream.resource(
      fn -> {nil, true} end,
      &stream_next_page(&1, list_fn, opts),
      fn _ -> :ok end
    )
  end

  @spec stream_next_page({String.t() | nil, boolean()}, list_fn(), keyword()) ::
          {[map()], {String.t() | nil, boolean()}} | {:halt, nil}
  defp stream_next_page({_cursor, false}, _list_fn, _opts), do: {:halt, nil}

  defp stream_next_page({cursor, true}, list_fn, opts) do
    page_opts = build_page_opts(opts, cursor)

    case list_fn.(page_opts) do
      {:ok, %{"data" => items, "has_more" => has_more}} ->
        next_cursor = next_cursor(items, has_more)
        {items, {next_cursor, has_more}}

      {:ok, %{"data" => items}} ->
        {items, {nil, false}}

      {:error, %Column.Error{} = error} ->
        raise error
    end
  end

  @spec next_cursor([map()], boolean()) :: String.t() | nil
  defp next_cursor(_items, false), do: nil
  defp next_cursor([], true), do: nil
  defp next_cursor(items, true), do: List.last(items)["id"]

  @spec build_page_opts(keyword(), String.t() | nil) :: keyword()
  defp build_page_opts(opts, nil) do
    Keyword.put(opts, :limit, opts[:limit] || 100)
  end

  defp build_page_opts(opts, cursor) do
    opts
    |> Keyword.put(:limit, opts[:limit] || 100)
    |> Keyword.put(:starting_after, cursor)
  end

  @doc "Fetches ALL pages for a list function, returning a flat list of all items."
  @spec fetch_all(list_fn(), keyword()) :: {:ok, list(map())} | {:error, Column.Error.t()}
  def fetch_all(list_fn, opts \\ []) do
    do_fetch_all(list_fn, opts, nil, [])
  end

  @spec do_fetch_all(list_fn(), keyword(), String.t() | nil, list()) ::
          {:ok, list(map())} | {:error, Column.Error.t()}
  defp do_fetch_all(list_fn, opts, cursor, acc) do
    page_opts = build_page_opts(opts, cursor)

    case list_fn.(page_opts) do
      {:ok, %{"data" => items, "has_more" => true}} ->
        next = List.last(items)["id"]
        do_fetch_all(list_fn, opts, next, acc ++ items)

      {:ok, %{"data" => items}} ->
        {:ok, acc ++ items}

      {:error, _} = err ->
        err
    end
  end

  # Only ever called with the pagination params accumulator built in build_params/1,
  # so the spec is narrowed to that concrete shape rather than a generic map().
  @spec maybe_put(pagination_params(), pagination_param_key(), pagination_param_value()) ::
          pagination_params()
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
