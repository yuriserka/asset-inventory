defmodule Domain.Operations.Purchase do
  defstruct symbol: nil,
            settle_date: nil,
            quantity: Decimal.new(0),
            unit_price: Decimal.new(0)

  @doc """
  Create a new sale.
  """
  @spec new(
          symbol :: String.t(),
          settle_date :: DateTime.t(),
          quantity :: Decimal.t(),
          unit_price :: Decimal.t()
        ) :: struct
  def new(
        symbol,
        settle_date,
        quantity,
        unit_price
      ) do
    %__MODULE__{
      symbol: symbol,
      settle_date: settle_date,
      quantity: quantity,
      unit_price: unit_price
    }
  end

  @doc """
  Sell a quantity of a purchase.
  """
  @spec sell(
          purchase :: %__MODULE__{},
          quantity :: Decimal.t()
        ) :: %__MODULE__{}
  def sell(purchase, quantity) do
    %__MODULE__{
      symbol: purchase.symbol,
      settle_date: purchase.settle_date,
      quantity: Decimal.sub(purchase.quantity, quantity),
      unit_price: purchase.unit_price
    }
  end
end
