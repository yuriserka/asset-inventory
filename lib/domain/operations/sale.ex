defmodule Domain.Operations.Sale do
  defstruct symbol: nil,
            sell_date: nil,
            quantity: Decimal.new(0),
            unit_price: Decimal.new(0),
            total_sold: Decimal.new(0)

  @doc """
  Create a new sale.
  """
  @spec new(
          symbol :: String.t(),
          sell_date :: DateTime.t(),
          quantity :: Decimal.t(),
          unit_price :: Decimal.t()
        ) :: struct
  def new(
        symbol,
        sell_date,
        quantity,
        unit_price
      ) do
    %__MODULE__{
      symbol: symbol,
      sell_date: sell_date,
      quantity: quantity,
      unit_price: unit_price,
      total_sold: Decimal.mult(quantity, unit_price)
    }
  end
end
