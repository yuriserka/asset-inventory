defmodule Domain.Operations.PurchaseTest do
  use ExUnit.Case
  doctest Domain.Operations.Purchase

  test "struct inits with default values" do
    purchase = %Domain.Operations.Purchase{}

    assert purchase == %Domain.Operations.Purchase{
             symbol: nil,
             settle_date: nil,
             quantity: Decimal.new(0),
             unit_price: Decimal.new(0)
           }
  end

  test "creates a new valid Purchase" do
    today = DateTime.utc_now()
    purchase = Domain.Operations.Purchase.new("APPL", today, Decimal.new(10), Decimal.new(100))

    assert purchase == %Domain.Operations.Purchase{
             symbol: "APPL",
             settle_date: today,
             quantity: Decimal.new(10),
             unit_price: Decimal.new(100)
           }
  end
end
