defmodule Domain.Operations.SaleTest do
  use ExUnit.Case
  doctest Domain.Operations.Sale

  test "struct inits with default values" do
    purchase = %Domain.Operations.Sale{}

    assert purchase == %Domain.Operations.Sale{
             symbol: nil,
             sell_date: nil,
             quantity: Decimal.new(0),
             unit_price: Decimal.new(0),
             total_sold: Decimal.new(0)
           }
  end

  test "creates a new valid Sale" do
    today = DateTime.utc_now()
    sale = Domain.Operations.Sale.new("APPL", today, Decimal.new(10), Decimal.new(100))

    assert sale == %Domain.Operations.Sale{
             symbol: "APPL",
             sell_date: today,
             quantity: Decimal.new(10),
             unit_price: Decimal.new(100),
             total_sold: Decimal.new(1000)
           }
  end
end
