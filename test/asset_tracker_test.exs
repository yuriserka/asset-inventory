defmodule AssetTrackerTest do
  use ExUnit.Case
  doctest AssetTracker

  test "creates a new valid AssetTracker" do
    assert AssetTracker.new() == %AssetTracker{assets: %{}}
  end

  test "adds a purchase to the asset tracker" do
    purchase =
      Domain.Operations.Purchase.new(
        "APPL",
        DateTime.utc_now(),
        Decimal.new(10),
        Decimal.new(100)
      )

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(purchase)

    assert asset_tracker == %AssetTracker{assets: %{"APPL" => :queue.from_list([purchase])}}
  end

  test "adds two purchases to the same asset" do
    today = DateTime.utc_now()
    future = today |> DateTime.add(10, :day)

    [p1, p2] = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(10), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", future, Decimal.new(3), Decimal.new(120))
    ]

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(p1)
      |> AssetTracker.add_purchase(p2)

    assert asset_tracker == %AssetTracker{assets: %{"APPL" => :queue.from_list([p1, p2])}}
  end

  test "adds two purchases to different assets" do
    purchases = [
      Domain.Operations.Purchase.new(
        "APPL",
        DateTime.utc_now(),
        Decimal.new(10),
        Decimal.new(100)
      ),
      Domain.Operations.Purchase.new("PETR", DateTime.utc_now(), Decimal.new(3), Decimal.new(120))
    ]

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))

    assert asset_tracker == %AssetTracker{
             assets: %{
               "APPL" => :queue.from_list([Enum.at(purchases, 0)]),
               "PETR" => :queue.from_list([Enum.at(purchases, 1)])
             }
           }
  end

  test "update asset tracker after a sale" do
    today = DateTime.utc_now()

    purchase =
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(10), Decimal.new(100))

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(purchase)
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", today, Decimal.new(5), Decimal.new(200))
      )

    assert asset_tracker ==
             {%AssetTracker{
                assets: %{
                  "APPL" =>
                    :queue.cons(
                      purchase |> Domain.Operations.Purchase.sell(Decimal.new(5)),
                      :queue.new()
                    )
                }
              }, Decimal.new(-500)}
  end

  test "on sale, should not delete purchase from asset_tracker if sale.quantity > purchase.quantity" do
    purchase =
      Domain.Operations.Purchase.new(
        "APPL",
        DateTime.utc_now(),
        Decimal.new(3),
        Decimal.new(100)
      )

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(purchase)
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", DateTime.utc_now(), Decimal.new(5), Decimal.new(200))
      )

    assert asset_tracker ==
             {%AssetTracker{
                assets: %{
                  "APPL" => :queue.from_list([purchase])
                }
              }, Decimal.new(-1000)}
  end

  test "on sale, update first the older purchase if more than 1 purchase" do
    today = DateTime.utc_now()
    future = today |> DateTime.add(10, :day)

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", future, Decimal.new(5), Decimal.new(150))
    ]

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", future, Decimal.new(5), Decimal.new(200))
      )

    assert asset_tracker ==
             {%AssetTracker{
                assets: %{
                  "APPL" =>
                    :queue.cons(
                      Enum.at(purchases, 1) |> Domain.Operations.Purchase.sell(Decimal.new(2)),
                      :queue.new()
                    )
                }
              }, Decimal.new(-400)}
  end

  test "on sale, update just the symbol if more than 1 symbol purchased" do
    today = DateTime.utc_now()
    future = today |> DateTime.add(10, :day)

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("PETR", today, Decimal.new(5), Decimal.new(150))
    ]

    asset_tracker =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", future, Decimal.new(3), Decimal.new(200))
      )

    assert asset_tracker ==
             {%AssetTracker{
                assets: %{
                  "PETR" =>
                    :queue.from_list([
                      Enum.at(purchases, 1)
                    ])
                }
              }, Decimal.new(-300)}
  end

  test "should correctly compute unrealized gain" do
    today = DateTime.utc_now()

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(5), Decimal.new(150))
    ]

    unrealized_gain_loss =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.unrealized_gain_or_loss("APPL", Decimal.new(200))

    assert unrealized_gain_loss == Decimal.new(-550)
  end

  test "should correctly compute unrealized loss" do
    today = DateTime.utc_now()

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(5), Decimal.new(150))
    ]

    unrealized_gain_loss =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.unrealized_gain_or_loss("APPL", Decimal.new(50))

    assert unrealized_gain_loss == Decimal.new(650)
  end

  test "should correctly compute unrealized gain with sales" do
    today = DateTime.utc_now()

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(5), Decimal.new(150))
    ]

    unrealized_gain_loss =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", today, Decimal.new(4), Decimal.new(200))
      )
      |> then(fn {asset_tracker, _} ->
        asset_tracker |> AssetTracker.unrealized_gain_or_loss("APPL", Decimal.new(500))
      end)

    assert unrealized_gain_loss == Decimal.new(-1400)
  end

  test "should correctly compute unrealized loss with sales" do
    today = DateTime.utc_now()

    purchases = [
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(3), Decimal.new(100)),
      Domain.Operations.Purchase.new("APPL", today, Decimal.new(5), Decimal.new(150))
    ]

    unrealized_gain_loss =
      AssetTracker.new()
      |> AssetTracker.add_purchase(Enum.at(purchases, 0))
      |> AssetTracker.add_purchase(Enum.at(purchases, 1))
      |> AssetTracker.add_sale(
        Domain.Operations.Sale.new("APPL", today, Decimal.new(4), Decimal.new(200))
      )
      |> then(fn {asset_tracker, _} ->
        asset_tracker |> AssetTracker.unrealized_gain_or_loss("APPL", Decimal.new(50))
      end)

    assert unrealized_gain_loss == Decimal.new(400)
  end
end
