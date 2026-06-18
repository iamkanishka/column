defmodule Column.Error do
  @moduledoc """
  Structured error type returned by all Column API calls.

  ## Error categories

  - `:api_error` — Column returned a 4xx/5xx response with an error body
  - `:network_error` — Transport-level failure (timeout, connection refused)
  - `:decode_error` — Response body could not be decoded as JSON
  - `:validation_error` — Local validation failed before making the request

  ## Usage

      case Column.BankAccounts.get("bacc_123") do
        {:ok, account} -> account
        {:error, %Column.Error{type: :api_error, status: 404}} -> handle_not_found()
        {:error, %Column.Error{type: :network_error}} -> handle_timeout()
        {:error, %Column.Error{} = err} -> handle_generic(err)
      end
  """

  @type error_type ::
          :api_error
          | :network_error
          | :decode_error
          | :validation_error

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t(),
          status: non_neg_integer() | nil,
          code: String.t() | nil,
          request_id: String.t() | nil,
          raw: map() | nil
        }

  defexception [:type, :message, :status, :code, :request_id, :raw]

  @impl Exception
  def message(%__MODULE__{message: msg, status: nil}), do: msg
  def message(%__MODULE__{message: msg, status: status}), do: "HTTP #{status}: #{msg}"

  @doc "Build from a Column API error response body + HTTP status."
  @spec from_response(non_neg_integer(), map(), String.t() | nil) :: t()
  def from_response(status, body, request_id \\ nil) do
    %__MODULE__{
      type: :api_error,
      status: status,
      message: Map.get(body, "message", "Unknown API error"),
      code: Map.get(body, "code"),
      request_id: request_id,
      raw: body
    }
  end

  @doc "Build from a network/transport error."
  @spec from_exception(Exception.t()) :: t()
  def from_exception(exception) do
    %__MODULE__{
      type: :network_error,
      message: Exception.message(exception),
      raw: nil
    }
  end

  @doc "Build a local validation error."
  @spec validation(String.t()) :: t()
  def validation(message) do
    %__MODULE__{type: :validation_error, message: message}
  end

  @doc "Build a JSON decode error."
  @spec decode(String.t()) :: t()
  def decode(message) do
    %__MODULE__{type: :decode_error, message: message}
  end
end
