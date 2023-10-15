defmodule Domain.Account.BankAccountTest do
  use ExUnit.Case
  doctest Domain.Account.BankAccount

  test "struct inits with default values" do
    banck_account = %Domain.Account.BankAccount{}

    assert banck_account == %Domain.Account.BankAccount{
             current_balance: Decimal.new(0),
             inventory: %AssetTracker{}
           }
  end

  test "buy_symbol adds a purchase to the inventory and update balance" do
    bank_account = %Domain.Account.BankAccount{}
    today = DateTime.utc_now()

    bank_account =
      bank_account
      |> Domain.Account.BankAccount.buy_symbol(
        "APPL",
        today,
        Decimal.new(10),
        Decimal.new(100)
      )

    assert bank_account == %Domain.Account.BankAccount{
             current_balance: Decimal.new(0),
             inventory: %AssetTracker{
               assets: %{
                 "APPL" =>
                   :queue.from_list([
                     Domain.Operations.Purchase.new(
                       "APPL",
                       today,
                       Decimal.new(10),
                       Decimal.new(100)
                     )
                   ])
               }
             }
           }
  end

  test "sell_symbol subtracts from purchase in the inventory and update balance" do
    today = DateTime.utc_now()
    future = today |> DateTime.add(1, :day)
    bank_account = %Domain.Account.BankAccount{}

    bank_account =
      bank_account
      |> Domain.Account.BankAccount.buy_symbol(
        "APPL",
        today,
        Decimal.new(100),
        Decimal.new(100)
      )
      |> Domain.Account.BankAccount.buy_symbol(
        "APPL",
        future,
        Decimal.new(50),
        Decimal.new(120)
      )
      |> Domain.Account.BankAccount.sell_symbol(
        "APPL",
        future,
        Decimal.new(70),
        Decimal.new(250)
      )

    purchases = [
      Domain.Operations.Purchase.new(
        "APPL",
        today,
        Decimal.new(100),
        Decimal.new(100)
      )
      |> Domain.Operations.Purchase.sell(Decimal.new(70)),
      Domain.Operations.Purchase.new(
        "APPL",
        future,
        Decimal.new(50),
        Decimal.new(120)
      )
    ]

    assert bank_account == %Domain.Account.BankAccount{
             current_balance: Decimal.new(-10500),
             inventory: %AssetTracker{assets: %{"APPL" => :queue.from_list(purchases)}}
           }
  end

  test "chain sell_symbol subtracts from purchase in the inventory and update balance" do
    today = DateTime.utc_now()
    future = today |> DateTime.add(1, :day)
    bank_account = %Domain.Account.BankAccount{}

    bank_account =
      bank_account
      |> Domain.Account.BankAccount.buy_symbol(
        "APPL",
        today,
        Decimal.new(100),
        Decimal.new(100)
      )
      |> Domain.Account.BankAccount.buy_symbol(
        "APPL",
        future,
        Decimal.new(50),
        Decimal.new(120)
      )
      |> Domain.Account.BankAccount.sell_symbol(
        "APPL",
        future,
        Decimal.new(70),
        Decimal.new(250)
      )
      |> Domain.Account.BankAccount.sell_symbol(
        "APPL",
        future,
        Decimal.new(80),
        Decimal.new(300)
      )

    assert bank_account == %Domain.Account.BankAccount{
             current_balance: Decimal.new(-25500),
             inventory: %AssetTracker{assets: %{}}
           }
  end
end
