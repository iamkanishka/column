defmodule Column.Params do
  @moduledoc """
  Parameter building and validation helpers.

  Provides a lightweight, chainable API for constructing validated request
  parameter maps before sending them to Column resource modules.

  ## Example

      import Column.Params

      params =
        new()
        |> put_required(:bank_account_id, "bacc_123")
        |> put_required(:counterparty_id, "cpty_456")
        |> put_required(:amount, 10_000)
        |> put_required(:currency_code, "USD")
        |> put_required(:type, "CREDIT")
        |> put_optional(:entry_class_code, "PPD")
        |> put_optional(:effective_date, nil)   # nil values are omitted
        |> validate_amount(:amount)
        |> build!()

      Column.ACH.create(params)
  """

  @type t :: %{
          params: map(),
          errors: [String.t()]
        }

  @doc "Start a new params builder."
  @spec new() :: %{params: %{}, errors: []}
  def new, do: %{params: %{}, errors: []}

  @doc "Add a required field. Adds a validation error if value is nil or empty string."
  @spec put_required(t(), atom() | String.t(), any()) :: t()
  def put_required(%{errors: errors} = acc, key, nil) do
    %{acc | errors: errors ++ ["#{key} is required"]}
  end

  def put_required(%{errors: errors} = acc, key, "") do
    %{acc | errors: errors ++ ["#{key} must not be empty"]}
  end

  def put_required(%{params: params} = acc, key, value) do
    %{acc | params: Map.put(params, to_string(key), value)}
  end

  @doc "Add an optional field. Nil values are silently omitted."
  @spec put_optional(t(), atom() | String.t(), any()) :: t()
  def put_optional(acc, _key, nil), do: acc

  def put_optional(%{params: params} = acc, key, value) do
    %{acc | params: Map.put(params, to_string(key), value)}
  end

  @doc "Add a field only when the condition is true."
  @spec put_when(t(), atom() | String.t(), any(), boolean()) :: t()
  def put_when(acc, _key, _value, false), do: acc
  def put_when(acc, key, value, true), do: put_optional(acc, key, value)

  @doc "Merge a map of optional fields, omitting nil values."
  @spec merge_optional(t(), map()) :: t()
  def merge_optional(%{params: params} = acc, extra) when is_map(extra) do
    filtered = extra |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()
    %{acc | params: Map.merge(params, filtered)}
  end

  @doc "Validate that an amount field is a positive integer (cents)."
  @spec validate_amount(t(), atom() | String.t()) :: t()
  def validate_amount(%{params: params, errors: errors} = acc, key) do
    str_key = to_string(key)

    case Map.get(params, str_key) do
      nil ->
        acc

      v when is_integer(v) and v > 0 ->
        acc

      v ->
        %{acc | errors: errors ++ ["#{key} must be a positive integer (got #{inspect(v)})"]}
    end
  end

  @doc "Validate that a currency_code field is a 3-letter ISO 4217 code."
  @spec validate_currency(t(), atom() | String.t()) :: t()
  def validate_currency(%{params: params, errors: errors} = acc, key) do
    str_key = to_string(key)

    case Map.get(params, str_key) do
      nil ->
        acc

      code when is_binary(code) and byte_size(code) == 3 ->
        acc

      v ->
        %{acc | errors: errors ++ ["#{key} must be a 3-letter ISO 4217 currency code (got #{inspect(v)})"]}
    end
  end

  @doc "Validate that a field matches one of the allowed values."
  @spec validate_inclusion(t(), atom() | String.t(), [any()]) :: t()
  def validate_inclusion(%{params: params, errors: errors} = acc, key, allowed) do
    str_key = to_string(key)

    case Map.get(params, str_key) do
      nil ->
        acc

      v ->
        if v in allowed do
          acc
        else
          %{acc | errors: errors ++ ["#{key} must be one of: #{Enum.join(allowed, ", ")} (got #{inspect(v)})"]}
        end
    end
  end

  @doc """
  Build the params map, raising `Column.Error` if there are validation errors.

  Returns the raw `map()` suitable for passing to Column resource functions.
  """
  @spec build!(t()) :: map()
  def build!(%{errors: [], params: params}), do: params

  def build!(%{errors: errors}) do
    message = Enum.join(errors, "; ")
    raise Column.Error, message: message, type: :validation_error
  end

  @doc """
  Build the params map, returning `{:ok, map()}` or `{:error, Column.Error.t()}`.
  """
  @spec build(t()) :: {:ok, map()} | {:error, Column.Error.t()}
  def build(%{errors: [], params: params}), do: {:ok, params}

  def build(%{errors: errors}) do
    err = %Column.Error{
      type: :validation_error,
      message: Enum.join(errors, "; ")
    }

    {:error, err}
  end
end
