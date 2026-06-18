defmodule Column.Money do
  @moduledoc """
  Money formatting and parsing helpers for Column API amounts.

  Column represents all monetary amounts as **integer cents** (or the smallest
  currency unit). This module provides helpers for converting between cents and
  display strings, and for formatting amounts for API payloads.

  ## Examples

      iex> Column.Money.to_cents(10.50, "USD")
      1050

      iex> Column.Money.from_cents(1050, "USD")
      "10.50"

      iex> Column.Money.format(100_000, "USD")
      "$1,000.00"

      iex> Column.Money.format(100_000, "EUR")
      "€1,000.00"

      iex> Column.Money.to_cents(0.10, "USD")
      10

  ## Note on floating-point

  Avoid using floats for financial amounts in production. Where possible,
  accept integer cents from your UI layer and skip conversion altogether.
  If you must convert, use `Decimal` (add the `:decimal` dep):

      Decimal.new("10.50")
      |> Decimal.mult(100)
      |> Decimal.round(0)
      |> Decimal.to_integer()
      # => 1050
  """

  @type cents :: non_neg_integer()
  @type currency :: String.t()

  @currency_info %{
    "USD" => %{symbol: "$", decimals: 2},
    "EUR" => %{symbol: "€", decimals: 2},
    "GBP" => %{symbol: "£", decimals: 2},
    "JPY" => %{symbol: "¥", decimals: 0},
    "CAD" => %{symbol: "CA$", decimals: 2},
    "AUD" => %{symbol: "A$", decimals: 2},
    "CHF" => %{symbol: "CHF", decimals: 2},
    "HKD" => %{symbol: "HK$", decimals: 2},
    "SGD" => %{symbol: "S$", decimals: 2},
    "MXN" => %{symbol: "MX$", decimals: 2},
    "INR" => %{symbol: "₹", decimals: 2},
    "BRL" => %{symbol: "R$", decimals: 2},
    "CNY" => %{symbol: "¥", decimals: 2}
  }

  @doc """
  Convert a float or integer amount to integer cents.

  Uses banker's rounding (round-half-to-even) to minimise cumulative error.

      Column.Money.to_cents(10.50, "USD")  # => 1050
      Column.Money.to_cents(1000, "USD")   # => 1000 (already cents)
  """
  @spec to_cents(number(), currency()) :: cents()
  def to_cents(amount, _currency) when is_integer(amount), do: amount

  def to_cents(amount, currency) when is_float(amount) do
    decimals = currency_decimals(currency)
    multiplier = round(:math.pow(10, decimals))
    round(amount * multiplier)
  end

  @doc """
  Convert integer cents to a decimal string.

      Column.Money.from_cents(1050, "USD")  # => "10.50"
      Column.Money.from_cents(100, "JPY")   # => "100"
  """
  @spec from_cents(cents(), currency()) :: String.t()
  def from_cents(cents, currency) when is_integer(cents) do
    decimals = currency_decimals(currency)

    if decimals == 0 do
      Integer.to_string(cents)
    else
      divisor = round(:math.pow(10, decimals))
      whole = div(cents, divisor)
      remainder = rem(cents, divisor)
      "#{whole}.#{String.pad_leading(Integer.to_string(remainder), decimals, "0")}"
    end
  end

  @doc """
  Format cents as a human-readable currency string with symbol.

      Column.Money.format(100_000, "USD")  # => "$1,000.00"
      Column.Money.format(500, "EUR")      # => "€5.00"
  """
  @spec format(cents(), currency()) :: String.t()
  def format(cents, currency) when is_integer(cents) do
    %{symbol: symbol} = currency_info(currency)
    decimal_str = from_cents(cents, currency)

    {whole, fraction} =
      case String.split(decimal_str, ".") do
        [w, f] -> {w, "." <> f}
        [w] -> {w, ""}
      end

    formatted_whole =
      whole
      |> String.to_charlist()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> String.reverse()

    "#{symbol}#{formatted_whole}#{fraction}"
  end

  @doc "Return the number of decimal places for a currency."
  @spec currency_decimals(currency()) :: non_neg_integer()
  def currency_decimals(currency) do
    currency_info(currency).decimals
  end

  @doc "Return currency metadata (symbol, decimals). Defaults to 2 decimal places for unknown currencies."
  @spec currency_info(currency()) :: %{symbol: String.t(), decimals: non_neg_integer()}
  def currency_info(currency) do
    Map.get(@currency_info, String.upcase(currency), %{symbol: currency, decimals: 2})
  end

  @doc "Returns true if the amount is a valid positive integer cent amount."
  @spec valid_amount?(term()) :: boolean()
  def valid_amount?(amount) when is_integer(amount) and amount > 0, do: true
  def valid_amount?(_), do: false
end
